seed=1111
num_operations=8000
cpu_num=`grep -c ^processor /proc/cpuinfo`

FAIRSEQ_DIR=fairseq/fairseq_cli
DATA_DIR=data/parallel
PROCESSED_DIR=process/$seed
MODEL_DIR=model/$seed

mkdir -p $PROCESSED_DIR

# Fairseqに読み込ませるためのバイナリーデータを作成する．

if [ -e $PROCESSED_DIR/bin ]; then
  echo 既にバイナリーデータは存在している．
else
  echo バイナリデータを作成する．

  mkdir -p $PROCESSED_DIR/bin
  subword-nmt learn-bpe -s $num_operations < $DATA_DIR/train_corrected.trg \
                        > $PROCESSED_DIR/trg_$num_operations.bpe
  subword-nmt apply-bpe -c $PROCESSED_DIR/trg_$num_operations.bpe \
                        < $DATA_DIR/train_corrected.src \
                        > $PROCESSED_DIR/train.src
  subword-nmt apply-bpe -c $PROCESSED_DIR/trg_$num_operations.bpe \
                        < $DATA_DIR/train_corrected.trg \
                        > $PROCESSED_DIR/train.trg
  subword-nmt apply-bpe -c $PROCESSED_DIR/trg_$num_operations.bpe \
                        < $DATA_DIR/dev.src \
                        > $PROCESSED_DIR/dev.src
  subword-nmt apply-bpe -c $PROCESSED_DIR/trg_$num_operations.bpe \
                        < $DATA_DIR/dev.trg \
                        > $PROCESSED_DIR/dev.trg

  python -u $FAIRSEQ_DIR/preprocess.py \
    --source-lang src \
    --target-lang trg \
    --trainpref $PROCESSED_DIR/train \
    --validpref $PROCESSED_DIR/dev \
    --testpref $PROCESSED_DIR/dev \
    --destdir $PROCESSED_DIR/bin \
    --workers $cpu_num \
    --joined-dictionary \
    --tokenizer space 
fi

# GECモデルの学習

mkdir -p $MODEL_DIR

python -u $FAIRSEQ_DIR/train.py $PROCESSED_DIR/bin \
  --save-dir $MODEL_DIR \
  --source-lang src \
  --target-lang trg \
  --log-format simple \
  --fp16 \
  --max-epoch 30 \
  --arch transformer_vaswani_wmt_en_de_big \
  --max-tokens 4096 \
  --optimizer adam \
  --adam-betas '(0.9, 0.98)' \
  --lr 0.0005 \
  --lr-scheduler inverse_sqrt \
  --warmup-updates 4000 \
  --warmup-init-lr 1e-07 \
  --stop-min-lr 1e-09 \
  --dropout 0.3 \
  --clip-norm 1.0 \
  --weight-decay 0.0 \
  --criterion label_smoothed_cross_entropy \
  --label-smoothing 0.1 \
  --num-workers $cpu_num \
  --no-epoch-checkpoints \
  --share-all-embeddings \
  --seed $seed


