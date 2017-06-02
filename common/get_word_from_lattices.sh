#!/bin/bash

set -e -o pipefail

# Begin configuration section.
cmd=run.pl
# End configuration section.

echo "$0 $@"  # Print the command line for logging

. ./utils/parse_options.sh

if [ $# != 2 ]; then
   echo "Get words from lattices"
   echo "Usage: common/get_word_from_lattices.sh <lang-dir> <decode_dir>"
   exit 1;
fi

[ -f path.sh ] && . ./path.sh;

lang=$1
dir=$2

nj=$(cat $dir/num_jobs)

$cmd JOB=1:$nj $dir/log/getwords.JOB.log \
      gunzip -c $dir/lat.JOB.gz \| \
      lattice-project ark:- ark,t:- \| \
      common/get_words_from_lat.py $lang/words.txt \> $dir/latwords.JOB || exit 1;
       
