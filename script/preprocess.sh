M2_DIR=$1
PARA_DIR=$2

# M2形式のFCEをパラレル形式に変換
python src/convert_m2_to_parallel.py $M2_DIR/fce/m2/fce.train.gold.bea19.m2 \
                                 $PARA_DIR/fce.train.src \
                                 $PARA_DIR/fce.train.trg
python src/convert_m2_to_parallel.py $M2_DIR/fce//m2/fce.dev.gold.bea19.m2 \
                                 $PARA_DIR/fce.dev.src \
                                 $PARA_DIR/fce.dev.trg
python src/convert_m2_to_parallel.py $M2_DIR/fce/m2/fce.test.gold.bea19.m2 \
                                 $PARA_DIR/fce.test.src \
                                 $PARA_DIR/fce.test.trg

# M2形式のNUCLEをパラレル形式に変換
python src/convert_m2_to_parallel.py $M2_DIR/release3.3/bea2019/nucle.train.gold.bea19.m2 \
                                 $PARA_DIR/nucle.train.src \
                                 $PARA_DIR/nucle.train.trg

# M2形式のLang-8をパラレル形式に変換
python src/convert_m2_to_parallel.py $M2_DIR/lang8/lang8.train.auto.bea19.m2 \
                                 $PARA_DIR/lang8.train.src \
                                 $PARA_DIR/lang8.train.trg

# M2形式のW&I+LOCNESSをパラレル形式に変換
python src/convert_m2_to_parallel.py $M2_DIR/wi+locness/m2/A.train.gold.bea19.m2 \
                                 $PARA_DIR/wi.trainA.src \
                                 $PARA_DIR/wi.trainA.trg
python src/convert_m2_to_parallel.py $M2_DIR/wi+locness/m2/B.train.gold.bea19.m2 \
                                 $PARA_DIR/wi.trainB.src \
                                 $PARA_DIR/wi.trainB.trg
python src/convert_m2_to_parallel.py $M2_DIR/wi+locness/m2/C.train.gold.bea19.m2 \
                                 $PARA_DIR/wi.trainC.src \
                                 $PARA_DIR/wi.trainC.trg

python src/convert_m2_to_parallel.py $M2_DIR/wi+locness/m2/A.dev.gold.bea19.m2 \
                                 $PARA_DIR/wi.devA.src \
                                 $PARA_DIR/wi.devA.trg
python src/convert_m2_to_parallel.py $M2_DIR/wi+locness/m2/B.dev.gold.bea19.m2 \
                                 $PARA_DIR/wi.devB.src \
                                 $PARA_DIR/wi.devB.trg
python src/convert_m2_to_parallel.py $M2_DIR/wi+locness/m2/C.dev.gold.bea19.m2 \
                                 $PARA_DIR/wi.devC.src \
                                 $PARA_DIR/wi.devC.trg
python src/convert_m2_to_parallel.py $M2_DIR/wi+locness/m2/N.dev.gold.bea19.m2 \
                                 $PARA_DIR/wi.devN.src \
                                 $PARA_DIR/wi.devN.trg

# 学習データのソース側の結合
cat $PARA_DIR/fce.train.src \
    $PARA_DIR/fce.dev.src \
    $PARA_DIR/fce.test.src \
    $PARA_DIR/nucle.train.src \
    $PARA_DIR/lang8.train.src \
    $PARA_DIR/wi.trainA.src \
    $PARA_DIR/wi.trainB.src \
    $PARA_DIR/wi.trainC.src \
    > $PARA_DIR/train.src

# 学習データのターゲット側の結合
cat $PARA_DIR/fce.train.trg \
    $PARA_DIR/fce.dev.trg \
    $PARA_DIR/fce.test.trg \
    $PARA_DIR/nucle.train.trg \
    $PARA_DIR/lang8.train.trg \
    $PARA_DIR/wi.trainA.trg \
    $PARA_DIR/wi.trainB.trg \
    $PARA_DIR/wi.trainC.trg \
    > $PARA_DIR/train.trg

# 学習データから訂正されていない文対を除去する
python src/remove.py --source-lang src --target-lang trg --trainpref $PARA_DIR/train

# 開発データのソース側の結合
cat $PARA_DIR/wi.devA.src \
    $PARA_DIR/wi.devB.src \
    $PARA_DIR/wi.devC.src \
    $PARA_DIR/wi.devN.src \
    > $PARA_DIR/dev.src

# 開発データのターゲット側の結合
cat $PARA_DIR/wi.devA.trg \
    $PARA_DIR/wi.devB.trg \
    $PARA_DIR/wi.devC.trg \
    $PARA_DIR/wi.devN.trg \
    > $PARA_DIR/dev.trg

# W&Iの評価データはソース側しか存在しないためそのままコピーしてくる
cp $M2_DIR/wi+locness/test/ABCN.test.bea19.orig $PARA_DIR/wi.test.src
