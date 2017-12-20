#!/bin/bash
#SBATCH -t 4:00:00
#SBATCH -p coin,batch-hsw,batch-wsm,batch-ivb,short-wsm,short-hsw,short-ivb

export LC_ALL=C

set -e

. ./path.sh

model=$1
lsuf=_$2

echo $model

if [ ! -f data/langs${lsuf}/$model/L.fst ]; then
   echo "lang" missing
   exit 1
fi



dir=data/langs${lsuf}/$model
tmpdir=data/langs${lsuf}/$model/local


if [ -f data/lm/$model/domainmix2/arpa ]; then
utils/build_const_arpa_lm.sh <(gzip -c < data/lm/$model/domainmix2/arpa) data/langs${lsuf}/${model} data/recog_langs${lsuf}/${model}_domainmix2
fi

if [ -f data/lm/$model/domain/arpa ]; then
utils/build_const_arpa_lm.sh <(gzip -c < data/lm/$model/domain/arpa) data/langs${lsuf}/${model} data/recog_langs${lsuf}/${model}_domain
fi

common/make_recog_lang.sh --inwordbackoff false data/lm/$model/domainmix1/arpa data/langs${lsuf}/$model data/recog_langs${lsuf}/${model}_domainmix1


