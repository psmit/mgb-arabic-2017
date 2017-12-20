#!/bin/bash


set -euo pipefail

# Begin configuration section.
cmd=run.pl
nj=20
scoring_opts=
# End configuration section.

echo "$0 $@"  # Print the command line for logging

[ -f ./path.sh ] && . ./path.sh; # source the path.
. parse_options.sh || exit 1;

if [ $# -ne 5 ]; then
  echo "Usage: common/interpolate_2lattices.sh [options] <data> <lang-dir|graph-dir> <lat-dir1> <lat-dir2> <decode-dir-out>"
  echo " e.g.: steps/decode_combine.sh data/lang data/test exp/dir1/decode exp/dir2/decode exp/combine_1_2/decode"
  echo "main options (for others, see top of script file)"
  echo "  --cmd <cmd>                              # Command to run in parallel with"
  exit 1;
fi

data=$1
lang=$2
srcdir1=$3
srcdir2=$4
dir=$5

sdata=$data/split${nj}utt
utils/split_data.sh --per-utt $data $nj
mkdir -p $dir

if [ ! -f  $srcdir1/lats$nj/num_jobs ]; then 
mkdir -p $srcdir1/lats$nj

$cmd JOB=1:$nj $srcdir1/log/copylat.JOB.log \
  gunzip -c $srcdir1/lat.*.gz \| \
  lattice-copy --include=$sdata/JOB/utt2spk ark:- ark:- \| \
  gzip -c \> $srcdir1/lats$nj/lat.JOB.gz

echo $nj > $srcdir1/lats$nj/num_jobs
fi

if [ ! -f  $srcdir2/lats$nj/num_jobs ]; then 
mkdir $srcdir2/lats$nj
$cmd JOB=1:$nj $srcdir2/log/copylat.JOB.log \
  gunzip -c $srcdir2/lat.*.gz \| \
  lattice-copy --include=$sdata/JOB/utt2spk ark:- ark:- \| \
  gzip -c \> $srcdir2/lats$nj/lat.JOB.gz

echo $nj > $srcdir2/lats$nj/num_jobs
fi

for i in $(seq 1 9); do
  steps/decode_combine.sh --scoring-opts "$scoring_opts" --cmd "$cmd" --weight1 0.$i $data $lang $srcdir1/lats$nj $srcdir2/lats$nj $dir/i0.$i 
done

