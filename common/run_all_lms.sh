#!/bin/bash

. common/slurm_dep_graph.sh

dataset=dev
iter=final
run=false

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# -lt 1 ]; then
   echo "usage: common/recognize.sh am_model lsuf"
   echo "e.g.:  common/recognize.sh --dataset yle-dev exp/chain/model/tdnn"
   echo "main options (for others, see top of script file)"

   exit 1;
fi

am=$1
lsuf=_gr

JOB_PREFIX=$(cat id)_



for model in $(ls -1 data/lm); do
#if echo $model | grep -v -q "word_f2"; then
#echo "skip $model"
#continue
#fi

prev=NONE
if $run || [ ! -f data/recog_langs${lsuf}/$model/G.fst ]; then
    job process_lm 35 1 NONE common/process_lm.sh $model $2
    run=true
    prev=LAST
fi

if $run || [ ! -f $am/graph_$model/HCLG.fst ];  then
    job mkgraph 40 4 $prev -- utils/mkgraph.sh --remove-oov --self-loop-scale 1.0 data/recog_langs${lsuf}/$model $am $am/graph_$model
    run=true
    prev=LAST
fi

dsname=$(basename $dataset)
extra=""
if [ "$dsname" != "dev" ]; then 
extra=_$dsname
fi
if [ "$iter" != "final" ]; then
extra=${iter}${extra}
fi

if $run || [ ! -f $am/decode${extra}_$model/wer_15_0.0 ]; then
   job recognize 3 4 $prev -- common/chain_recog_iter_graph.sh --dataset $dataset --iter $iter $am data/recog_langs${lsuf}/$model
   run=true
   prev=LAST
fi


if $run || [ ! -f $am/decode${extra}_${model}_rnn/wer_15_0.0 ]; then
  if [ -f data/lm/$model/rescore/nnlm.h5 ]; then
    if [ ! -f data/recog_langs${lsuf}/$model/nnlm.h5 ]; then
      ln -rs data/lm/$model/rescore/nnlm.h5 data/recog_langs${lsuf}/$model/nnlm.h5 
    fi
    job rescore_rnn 1 24 $prev -- common/lmrescore_theanolm_a.sh --scoring-opts "--min-lmwt 4" --theanolm-lmscale 9.0 --theanolm-beam 600 --theanolm-recombination 1000 --theanolm-maxtokens 150 --self-loop-scale 1.0 --nj 100 --cmd "slurm.pl --mem 24G"  data/recog_langs${lsuf}/$model data/recog_langs${lsuf}/$model data/$dataset ${am}/decode${extra}_$model ${am}/decode${extra}_${model}_rnn
    run=true
    prev=LAST
  fi
fi


 
done
