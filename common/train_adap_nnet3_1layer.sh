#!/bin/bash

set -euo pipefail 

learning_rate=0.0015
learn_layer=tdnn3.affine
xent_regularize=0.025
deriv_time=-12
deriv_time_relative=12
left_context=4
right_context=4
frame_shift=0
num_egs=17

echo "$0 $@"  # Print the command line for logging

. ./utils/parse_options.sh

if [ $# != 2 ]; then
   echo "Usage: steps/train_adap [options] dat-dir eg-dir"
   echo "options: [--cmd (run.pl|queue.pl [queue opts])]"
   exit 1;
fi

[ -f path.sh ] && . ./path.sh;


dir=$1
egs=$2


nnet3-am-copy --edits="set-learning-rate name=* learning-rate=0.0;set-learning-rate name=$learn_layer* learning-rate=$learning_rate" $dir/start.mdl $dir/0.mdl

for i in $(seq 1 100); do
prev=$(( $i - 1 ))
egg=$(( $i % $num_egs + 1 ))
nnet3-chain-train --verbose=1 \
--apply-deriv-weights=False \
--l2-regularize=5e-05 \
--leaky-hmm-coefficient=0.1 \
--xent-regularize=$xent_regularize \
--optimization.min-deriv-time=$deriv_time \
--optimization.max-deriv-time-relative=$deriv_time_relative \
--print-interval=10 \
--momentum=0.0 \
--max-param-change=2.0 \
"nnet3-am-copy --raw=true $dir/${prev}.mdl - |" \
$dir/den.fst \
"ark,bg:nnet3-chain-copy-egs --left-context=$left_context --right-context=$right_context --frame-shift=$frame_shift ark:${egs}/cegs.${egg}.ark ark:- | nnet3-chain-shuffle-egs --buffer-size=5000 --srand=1300 ark:- ark:- | nnet3-chain-merge-egs --minibatch-size=64,32 ark:- ark:- |" \
$dir/${i}.raw

nnet3-am-copy --set-raw-nnet=$dir/$i.raw --scale=1 $dir/${prev}.mdl $dir/${i}.mdl
done
