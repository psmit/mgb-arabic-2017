#!/bin/bash
set -e

export LC_ALL=C

# Begin configuration section.
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 2 ]; then
   echo "usage: common/train_phonetisaurus lexicon_in wfst_out"
   echo "e.g.:  common/train_phonetisaurus data/lexicon/lexicon.txt data/lexicon/g2p_wfsa"
   echo "main options (for others, see top of script file)"
   exit 1;
fi

lexicon_in=$1
wfst_out=$2

tmpdir=$(mktemp -d)

echo $(date) "Train g2p"
phonetisaurus-align --s1s2_sep="]" --input=${lexicon_in} -ofile=${tmpdir}/corpus | echo

estimate-ngram -s FixKN -o 3 -t ${tmpdir}/corpus -wl ${tmpdir}/arpa

phonetisaurus-arpa2wfst --lm=${tmpdir}/arpa --ofile=${wfst_out} --split="]"

echo $(date) "Take out the trash"
rm -Rf ${tmpdir}
