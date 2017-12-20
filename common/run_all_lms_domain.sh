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


srun=$run

for model in $(ls -1 data/lm ); do
#if echo $model | grep -v -q "word_f2"; then
#echo "skip $model"
#continue
#fi
run=$srun
prev=NONE
if $run || [ ! -f data/recog_langs${lsuf}/${model}_domainmix1/G.fst ]; then
    echo "Run: $run , or data/recog_langs${lsuf}/$model/G.fst doesn't exist"
    job process_lm 30 1 NONE common/process_lm_domain.sh $model gr
    run=true
    prev=LAST
fi

if $run || [ ! -f $am/graph_${model}_domainmix1/HCLG.fst ];  then
    echo "Run: $run , or $am/graph_$model/HCLG.fst"
    job mkgraph 45 4 $prev -- utils/mkgraph.sh --self-loop-scale 1.0 data/recog_langs${lsuf}/${model}_domainmix1 $am $am/graph_${model}_domainmix1
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

if $run || { [ ! -f $am/decode${extra}_${model}_domainmix1/scoring_mrwer/best_mrwer ] && [ ! -f $am/decode${extra}_${model}_domainmix1/scoring_kaldi/best_wer ]; }; then
   
   job recognize_$model 4 4 $prev -- common/chain_recog_iter_graph_domain.sh --dataset $dataset --iter $iter $am data/recog_langs${lsuf}/${model}
   run=true
   prev=recognize_$model
fi


#suf=big
#for i in $(seq 1 9); do

#if [ ! -f $am/decode${extra}_${model}_interp_${suf}/i0.${i}/scoring_mrwer/best_mrwer ] && [ ! -f $am/decode${extra}_${model}_interp_${suf}/i0.${i}/scoring_kaldi/best_wer ]; then

#SLURM_EXTRA_ARGS=" -c 8"
#job comb_${suf}_$i 3 4 $prev -- steps/decode_combine.sh --weight1 0.$i --scoring-opts "--min-lmwt 4" --cmd "run.pl --max-jobs-run 8" data/$dataset data/langs_gr/$model ${am}/decode${extra}_${model}  ${am}/decode${extra}_${model}_${suf} ${am}/decode${extra}_${model}_interp_$suf/i0.$i

#fi
#done



#SLURM_EXTRA_ARGS=""
#job best_${suf} 2 4 comb_${suf}_1,comb_${suf}_2,comb_${suf}_3,comb_${suf}_4,comb_${suf}_5,comb_${suf}_6,comb_${suf}_7,comb_${suf}_8,comb_${suf}_9 -- common/select_best.sh ${am}/decode${extra}_${model}_interp_$suf

#for suf in "egy" "domain"; do
#for i in $(seq 1 9); do

#if [ ! -f $am/decode${extra}_${model}_interp_${suf}/i0.${i}/scoring_mrwer/best_mrwer ] && [ ! -f $am/decode${extra}_${model}_interp_${suf}/i0.${i}/scoring_kaldi/best_wer ]; then

#SLURM_EXTRA_ARGS=" -c 8"
#job comb_${suf}_$i 3 4 best_big -- steps/decode_combine.sh --weight1 0.$i --scoring-opts "--min-lmwt 4" --cmd "run.pl --max-jobs-run 8" data/$dataset data/langs_gr/$model ${am}/decode${extra}_${model}  ${am}/decode${extra}_${model}_${suf} ${am}/decode${extra}_${model}_interp_$suf/i0.$i
#
#fi
#done
#SLURM_EXTRA_ARGS=""
#job best_${suf} 2 4 comb_${suf}_1,comb_${suf}_2,comb_${suf}_3,comb_${suf}_4,comb_${suf}_5,comb_${suf}_6,comb_${suf}_7,comb_${suf}_8,comb_${suf}_9 -- common/select_best.sh ${am}/decode${extra}_${model}_interp_$suf
#done


#continue
#if [ ! -f $am/decode${extra}_${model}_rnn/num_jobs ]; then
#  if [ -f data/lm/$model/rescore/nnlm.h5 ]; then
#    if [ ! -e data/recog_langs${lsuf}/$model/nnlm.h5 ]; then
#      ln -rs data/lm/$model/rescore/nnlm.h5 data/recog_langs${lsuf}/$model/nnlm.h5 

tlbeam=600
tlmaxtok=120
tlrecomb=20
mem=20
if [[ $model == word* ]]; then
tlbeam=500
tlmaxtok=100
tlrecomb=10
mem=40
fi

if [ ! -f $am/decode${extra}_${model}_domainmix1_rnn_bg/num_jobs ]; then
  if [ -f data/lm/$model/rescore/nnlm.h5 ]; then
    mkdir -p data/recog_langs${lsuf}/${model}_egymix1
    if [ ! -e data/recog_langs${lsuf}/${model}_egymix1/nnlm.h5 ]; then
      ln -rs data/lm/$model/rescore/nnlm.h5 data/recog_langs${lsuf}/${model}_egymix1/nnlm.h5 
    fi
    job rescore_rnn 4 24 $prev -- common/lmrescore_theanolm_b.sh --beam 8 --scoring-opts "--min-lmwt 4" --lmscale 8 --theanolm-beam $tlbeam --theanolm-recombination $tlrecomb --theanolm-maxtokens $tlmaxtok --cmd "slurm.pl --mem ${mem}G"  data/recog_langs${lsuf}/${model}_domainmix2 data/recog_langs${lsuf}/${model}_egymix1 data/$dataset ${am}/decode${extra}_${model}_domainmix1_domainmix2 ${am}/decode${extra}_${model}_domainmix1_rnn_bg
  fi
fi


if [ ! -f $am/decode${extra}_${model}_domainmix1_rnn_domain/num_jobs ]; then
  if [ -f data/lm/$model/domain/nnlm.h5 ]; then
    mkdir -p data/recog_langs${lsuf}/${model}_domain
    if [ ! -e data/recog_langs${lsuf}/${model}_domain/nnlm.h5 ]; then
      ln -rs data/lm/$model/domain/nnlm.h5 data/recog_langs${lsuf}/${model}_domain/nnlm.h5 
    fi
    job rescore_rnn 4 24 $prev -- common/lmrescore_theanolm_b.sh --beam 8 --scoring-opts "--min-lmwt 4" --lmscale 8 --theanolm-beam $tlbeam --theanolm-recombination $tlrecomb --theanolm-maxtokens $tlmaxtok --cmd "slurm.pl --mem ${mem}G"  data/recog_langs${lsuf}/${model}_domainmix2 data/recog_langs${lsuf}/${model}_domain data/$dataset ${am}/decode${extra}_${model}_domainmix1_domainmix2 ${am}/decode${extra}_${model}_domainmix1_rnn_domain
  fi
fi
prev=LAST

if [ -f $am/decode${extra}_${model}_domainmix1_rnn_bg/scoring_kaldi/best_wer ] && [ ! -f ${am}/decode${extra}_${model}_domainmix1_rnn_bg_interp/best/scoring_kaldi/best_wer ] ; then
  job interp 3 4 NONE -- common/interpolate_2lattices_simple.sh --start 3 --scoring-opts "--min-lmwt 4" data/$dataset data/recog_langs${lsuf}/${model}_domainmix2 ${am}/decode${extra}_${model}_domainmix1_domainmix2 ${am}/decode${extra}_${model}_domainmix1_rnn_bg ${am}/decode${extra}_${model}_domainmix1_rnn_bg_interp
fi

if [ -f $am/decode${extra}_${model}_domainmix1_rnn_domain/scoring_kaldi/best_wer ] && [ ! -f ${am}/decode${extra}_${model}_domainmix1_rnn_domain_interp/best/scoring_kaldi/best_wer ] ; then
  job interp 3 4 NONE -- common/interpolate_2lattices_simple.sh --start 2 --scoring-opts "--min-lmwt 4" data/$dataset data/recog_langs${lsuf}/${model}_domainmix2 ${am}/decode${extra}_${model}_domainmix1_domainmix2 ${am}/decode${extra}_${model}_domainmix1_rnn_domain ${am}/decode${extra}_${model}_domainmix1_rnn_domain_interp
fi

if [ -f ${am}/decode${extra}_${model}_domainmix1_rnn_bg_interp/best/scoring_kaldi/best_wer ] && [ -f ${am}/decode${extra}_${model}_domainmix1_rnn_domain_interp/best/scoring_kaldi/best_wer ] && [ ! -f ${am}/decode${extra}_${model}_domainmix1_rnn_both_interp/best/scoring_kaldi/best_wer ]; then
   job interp_both 3 4 NONE -- common/interpolate_2lattices_simple.sh --start 3 --scoring-opts "--min-lmwt 4" data/$dataset data/recog_langs${lsuf}/${model}_domainmix2 ${am}/decode${extra}_${model}_domainmix1_rnn_bg_interp/best ${am}/decode${extra}_${model}_domainmix1_rnn_domain_interp/best ${am}/decode${extra}_${model}_domainmix1_rnn_both_interp  
fi

done
