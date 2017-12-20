#!/bin/bash
#SBATCH -t 4:00:00
#SBATCH -p coin,batch-hsw,batch-wsm,batch-ivb,short-wsm,short-hsw,short-ivb

export LC_ALL=C

set -e

. ./path.sh

model=$1
lsuf=_$2

echo $model

if [ ! -f data/lm/$model/small/arpa ]; then
   echo "arpa" missing
   exit 1
fi
if [ ! -f data/lm/$model/type ]; then
   echo "type" missing
   exit 1
fi

echo data/lm/$model/small/arpa

common/extract_vocab_from_arpa.py < data/lm/$model/small/arpa > data/lm/$model/vocab

local/make_recog_dict.sh data/lm/$model/vocab data/dicts${lsuf}/$model $2
t=$(cat data/lm/$model/type)

case $t in
word)
  extra=1
  ;;
*)
  extra=3
  ;;
esac

utils/prepare_lang.sh --phone-symbol-table data/lang${lsuf}/phones.txt --num-extra-phone-disambig-syms $extra data/dicts${lsuf}/$model "<UNK>" data/langs${lsuf}/$model/local data/langs${lsuf}/$model

dir=data/langs${lsuf}/$model
tmpdir=data/langs${lsuf}/$model/local

case $t in
*suf)
  common/make_lfst_suf.py $(tail -n1 $dir/phones/disambig.txt) < $tmpdir/lexiconp_disambig.txt | fstcompile --isymbols=$dir/phones.txt --osymbols=$dir/words.txt --keep_isymbols=false --keep_osymbols=false | fstaddselfloops  $dir/phones/wdisambig_phones.int $dir/phones/wdisambig_words.int | fstarcsort --sort_type=olabel > $dir/L_disambig.fst
  ;;
*pre)
  common/make_lfst_pre.py $(tail -n1 $dir/phones/disambig.txt) < $tmpdir/lexiconp_disambig.txt | fstcompile --isymbols=$dir/phones.txt --osymbols=$dir/words.txt --keep_isymbols=false --keep_osymbols=false | fstaddselfloops  $dir/phones/wdisambig_phones.int $dir/phones/wdisambig_words.int | fstarcsort --sort_type=olabel > $dir/L_disambig.fst
  ;;
*aff)
  common/make_lfst_aff.py $(tail -n1 $dir/phones/disambig.txt) < $tmpdir/lexiconp_disambig.txt | fstcompile --isymbols=$dir/phones.txt --osymbols=$dir/words.txt --keep_isymbols=false --keep_osymbols=false | fstaddselfloops  $dir/phones/wdisambig_phones.int $dir/phones/wdisambig_words.int | fstarcsort --sort_type=olabel > $dir/L_disambig.fst
  ;;
*wma)
  common/make_lfst_wma.py $(tail -n3 $dir/phones/disambig.txt) < $tmpdir/lexiconp_disambig.txt | fstcompile --isymbols=$dir/phones.txt --osymbols=$dir/words.txt --keep_isymbols=false --keep_osymbols=false | fstaddselfloops  $dir/phones/wdisambig_phones.int $dir/phones/wdisambig_words.int | fstarcsort --sort_type=olabel > $dir/L_disambig.fst
  ;;
*)
  echo "word model, L_disambig.fst not edited"
  ;;
esac

if [ -f data/lm/$model/rescore/arpa ]; then
utils/build_const_arpa_lm.sh <(gzip -c < data/lm/$model/rescore/arpa) data/langs${lsuf}/${model} data/recog_langs${lsuf}/${model}_big
fi

if [ -f data/lm/$model/domain/arpa ]; then
utils/build_const_arpa_lm.sh <(gzip -c < data/lm/$model/domain/arpa) data/langs${lsuf}/${model} data/recog_langs${lsuf}/${model}_domain
fi

if [ -f data/lm/$model/egy/arpa ]; then
utils/build_const_arpa_lm.sh <(gzip -c < data/lm/$model/egy/arpa) data/langs${lsuf}/${model} data/recog_langs${lsuf}/${model}_egy
fi
common/make_recog_lang.sh --inwordbackoff false data/lm/$model/small/arpa data/langs${lsuf}/$model data/recog_langs${lsuf}/$model


