#!/bin/bash

set -euo pipefail

echo "$0 $@"  # Print the command line for logging

scoring_opts="--min-lmwt 4"
cmd="run.pl --max-jobs-run 4"

[ -f ./path.sh ] && . ./path.sh; # source the path.
. parse_options.sh || exit 1;

if [ $# != 5 ]; then
    echo "Usage: common/to_word_lat.sh data old_lang new_lang decode_dir to_dir"
fi

data=$1
oldlang=$2
newlang=$3
indir=$4
outdir=$5

nj=$(cat $indir/num_jobs)

mkdir -p $outdir/log

wb=0
if grep -q "<w> " $oldlang/words.txt; then
    wb=$(grep "<w> " $oldlang/words.txt | cut -f2 -d" ")
fi

if [ ! -f $indir/word_mapper ] && [ -f $oldlang/word_mapper ]; then
   cp $oldlang/word_mapper $indir/word_mapper 
fi
echo "<UNK> $(grep "<UNK>" $oldlang/words.txt | cut -f2 -d" ")" | cat $indir/word_mapper - | utils/apply_map.pl -f 1 --permissive $newlang/words.txt | grep -E "^[0-9 ]+$" | common/subword_to_word_fst.py $wb | fstcompile | fstdeterminize > $indir/T.fst

cp $indir/num_jobs $outdir/num_jobs

$cmd JOB=1:$nj $outdir/log/towordlat.JOB.log \
    gunzip -c $indir/lat.JOB.gz \| \
    lattice-compose ark:- $indir/T.fst ark:- \| \
    gzip -c \> $outdir/lat.JOB.gz


local/score.sh --cmd "$cmd" $scoring_opts $data $newlang $outdir

