#!/bin/bash

. ./path.sh

dir=$1


for f in $dir/*.train; do
fn=$(basename $f .train)
for d in 0.5 0.1 0.05 0.01 0.005 0.001 0.0005 0.0001 0.00001 0.000001 0.0; do
#for d in 0.001; do

if [ -f $dir/slurmjob-$fn-$d ]; then
  if squeue -j $(cat $dir/slurmjob-$fn-$d) >/dev/null 2>/dev/null; then
    echo "Job already running"
    continue;
  fi
fi

if [ -f $dir/arpa-$fn-$d ] && [[ $(wc -l < $dir/arpa-$fn-$d) > 10 ]]; then
  echo "Job already finished?"
  continue;
fi

partitions="coin,batch-ivb,batch-wsm,batch-hsw,hugemem" #,short-wsm,short-hsw,short-ivb"
ret=$(sbatch -p $partitions -t 2-00:00:00 --job-name=varikn -e $dir/log-%j.out -o $dir/log-%j.out --mem-per-cpu 24G $depend -- common/train_varikn_background.sh $dir $fn $d)
echo $ret
rid=$(echo $ret | awk '{print $4;}')
echo "$rid" > $dir/slurmjob-$fn-$d
done
done
