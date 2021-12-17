seed=1111
num_operations=8000
beam=5
test_data=$1 # wi conll jfleg

FAIRSEQ_DIR=fairseq/fairseq_cli
DATA_DIR=data
PROCESSED_DIR=process
MODEL_DIR=model/$seed
OUTPUT_DIR=output
EVAL_DIR=eval

export PYTHONPATH=$FAIRSEQ_DIR

mkdir -p $OUTPUT_DIR/$seed

if [ -e $PROCESSED_DIR/$seed/${test_data}_bin ]; then
  echo $test_data のバイナリーデータは既に存在する．
else
  echo $test_data のバイナリーデータを作成する．
  cpu_num=`grep -c ^processor /proc/cpuinfo`
  if [ $test_data = 'wi' ]; then
    subword-nmt apply-bpe -c $PROCESSED_DIR/$seed/trg_$num_operations.bpe \
                          < $DATA_DIR/wi.test.src \
                          > $PROCESSED_DIR/$seed/$test_data.src
  elif [ $test_data = 'conll' ]; then
    subword-nmt apply-bpe -c $PROCESSED_DIR/$seed/trg_$num_operations.bpe \
                          < $DATA_DIR/conll14st-test-data/noalt/conll2014.src \
                          > $PROCESSED_DIR/$seed/$test_data.src
  elif [ $test_data = 'jfleg' ]; then
    subword-nmt apply-bpe -c $PROCESSED_DIR/$seed/trg_$num_operations.bpe \
                          < $DATA_DIR/jfleg/test/test.src \
                          > $PROCESSED_DIR/$seed/$test_data.src
  fi

  cp $PROCESSED_DIR/$seed/$test_data.src $PROCESSED_DIR/$seed/$test_data.trg
  python -u $FAIRSEQ_DIR/preprocess.py \
    --source-lang src \
    --target-lang trg \
    --trainpref $PROCESSED_DIR/$seed/train \
    --validpref $PROCESSED_DIR/$seed/$test_data \
    --testpref $PROCESSED_DIR/$seed/$test_data \
    --destdir $PROCESSED_DIR/$seed/${test_data}_bin \
    --srcdict $PROCESSED_DIR/$seed/bin/dict.src.txt \
    --tgtdict $PROCESSED_DIR/$seed/bin/dict.trg.txt \
    --workers $cpu_num \
    --tokenizer space
fi

# GECモデルを用いて評価データの推論
python -u $FAIRSEQ_DIR/interactive.py $PROCESSED_DIR/$seed/bin \
  --source-lang src \
  --target-lang trg \
  --path $MODEL_DIR/checkpoint_best.pt \
  --beam $beam \
  --nbest $beam \
  --no-progress-bar \
  --buffer-size 1024 \
  --batch-size 32 \
  --log-format simple \
  --remove-bpe \
  < $PROCESSED_DIR/$seed/$test_data.src  > $OUTPUT_DIR/$seed/$test_data.nbest.tok

# n-bestから1-bestを抽出する
cat $OUTPUT_DIR/$seed/$test_data.nbest.tok | grep "^H"  | python -c "import sys; x = sys.stdin.readlines(); x = ' '.join([ x[i] for i in range(len(x)) if (i % ${beam} == 0) ]); print(x)" | cut -f3 > $OUTPUT_DIR/$seed/$test_data.best.tok
sed -i '$d' $OUTPUT_DIR/$seed/$test_data.best.tok

# 推論結果を評価する
if [ $test_data = 'conll' ]; then
  CONLL_DIR=data/conll14st-test-data/noalt/
  $EVAL_DIR/m2_python3/m2scorer $OUTPUT_DIR/$seed/$test_data.best.tok $CONLL_DIR/official-2014.combined.m2 > $OUTPUT_DIR/$seed/$test_data.eval
elif [ $test_data = 'jfleg' ]; then
  JFLEG_DIR=data/jfleg/test
  $EVAL_DIR/gec-ranking_python3/scripts/compute_gleu -s $JFLEG_DIR/test.src -r $JFLEG_DIR/test.ref0 $JFLEG_DIR/test.ref1 $JFLEG_DIR/test.ref2 $JFLEG_DIR/test.ref3 -o $OUTPUT_DIR/$seed/$test_data.best.tok -n 4 > $OUTPUT_DIR/$seed/$test_data.eval
fi
