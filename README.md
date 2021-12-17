# Fairseqで文法誤り訂正モデルを学習，推論と評価する

文法誤り訂正 (Grammatical Error Correction; GEC) に入門する[ブログ記事]()のコードである．

## セットアップ

実行環境はpython3.9であり，`pip install -r requirements.txt`により必要なライブラリをインストールする．

### Fairseの準備
```shell
git clone https://github.com/pytorch/fairseq.git
cd fairseq
pip install --editable ./
cd ../
```

## データセットの入手と前処理

W&I+LOCNESSとFCEはwgetによりダウンロードすることが可能である．Lang-8とNUCLEはリクエストが必要であるため，各自申請して`data/m2`に配置する．これらのデータはM2形式で配布されており，Fairseqで取り扱えるようにパラレル形式（ソースデータとターゲットデータ）に変換する必要がある．
```shell
# W&I+LOCNESSとFCEデータをダウンロードし`data/m2`ディレクトリに配置する．Lang-8とNUCLEは適宜リクエストして配置する．
M2_DIR=data/m2
PARA_DIR=data/parallel
mkdir -p $M2_DIR
mkdir -p $PARA_DIR
wget https://www.cl.cam.ac.uk/research/nl/bea2019st/data/fce_v2.1.bea19.tar.gz -O - | tar xvf - -C $M2_DIR
wget https://www.cl.cam.ac.uk/research/nl/bea2019st/data/wi+locness_v2.1.bea19.tar.gz -O - | tar xvf - -C $M2_DIR
# データに対して前処理（1：M2形式からパラレルデータ形式に変換する，2：データを結合する，3：訂正されていない文対を除外する）を行う．
./script/preprocess.sh $M2_DIR $PARA_DIR
```

上記のコマンドによりW&I+LOCNESSの評価データはダウンロードされているが，CoNLL-2014とJFLEGは以下のコマンドで`data`にダウンロードする必要がある．

```shell
# CoNLL-2014のダウンロードとパラレルデータ形式に変換
wget https://www.comp.nus.edu.sg/~nlp/conll14st/conll14st-test-data.tar.gz -O - | tar xvf - -C data
python src/convert_m2_to_parallel.py data/conll14st-test-data/noalt/official-2014.combined.m2 data/conll14st-test-data/noalt/conll2014.src data/conll14st-test-data/noalt/conll2014.trg
# JFLEGのダウンロード
git clone https://github.com/keisks/jfleg.git data/jfleg
```

## GECモデルの学習

`train.sh`を使い作成したデータをバイナリーデータにしGECモデルを学習する．ここではGECモデルとしてTransformer-bigを使用する．
```shell
./script/train.sh
```


## GECモデルの推論と評価

推論結果を評価するために評価指標を3つ`eval`ディレクトリに配置する．W&I+LOCNESSはCodaLabで評価するためERRANTは直接使わない．
```shell
mkdir eval
# M2のダウンロード
git clone https://github.com/kanekomasahiro/m2_python3.git eval/m2_python3
# GLEUのダウンロード
git clone https://github.com/kanekomasahiro/gec-ranking_python3.git eval/gec-ranking_python3
# 使わないが一応ERRANTのダウンロード
git clone https://github.com/chrisjbryant/errant.git eval/errant
```

`interactive.sh`を使い学習したモデルで評価データに対して推論を行う．wi，conllまたはjflegのどれを推論するか引数で指定する．そして，CoNLL-2014（評価に時間がかかることがある）とJFLEGに対しては推論結果の評価も行われる．評価結果や出力結果は`output/$seed`に保存される．
```shell
./script/interactive.sh [wi/conll/jfleg]
```
W&I+LOCNESSは評価データのターゲット側が公開されていないため，[CodaLab](https://competitions.codalab.org/competitions/20228)にGECモデルの推論結果を投稿する必要がある．アカウントを作成し，`zip`コマンドにより推論結果を圧縮しParticipateのSubmitを押してアップロードすることでスコアを取得できる．
seedによって1.5ぐらい前後するがスコアとしてはW&I+LOCNESS: 50, CoNLL-2014: 49, JFLEG: 53がでる．

