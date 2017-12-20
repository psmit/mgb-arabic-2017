#!/bin/bash

. ./common/slurm_dep_graph.sh

SLURM_EXTRA_ARGS="-c 5"

for am in exp/chain/model/gr_tdnn_blstm_9_a exp/chain/model/gr_tdnn_lstm_9_a; do
for rl in data/recog_langs_gr/*_domainmix1; do

for suf in "" "_rnn_domain" "_rnn_bg" "_domainmix2"; do

name=$am/decode1300_test_$(basename $rl)$suf
if [ -f $name/scoring_kaldi/best_wer ]; then

job score 4 4 NONE -- local/score.sh --cmd "run.pl --max-jobs-run 4" --min-lmwt 4 data/test $rl $name
echo $name

fi


done

done
done
