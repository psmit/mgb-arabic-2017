#!/bin/bash

set -euo pipefail
echo "$0 $@"  # Print the command line for logging

. ./path.sh # source the path.

if [ $# != 1 ]; then
    echo "usage: common/train_varikn_background_ppl.sh dir"
    
    exit 1;
fi

dir=$1
pdir=$(dirname $dir)



echo "$dir "
btype=$(echo $dir | grep -o "word\|wma\|pre\|suf\|aff" | head -n1)

for d in $pdir/devel*; do
for arpa in $dir/arpa-*; do
if [[ $(wc -l < $arpa) < 10 ]]; then
continue
fi

ppl=$dir/ppl-$(basename $d)-$(basename $arpa).txt

if [ -f $ppl ]; then
continue
fi

case $btype in
pre)
printf "^<s>\n^+" > $dir/mb.txt
perplexity -a $arpa -t 1 -X $dir/mb.txt $d $ppl
;;
suf)
printf "^<s>\n+$" > $dir/mb.txt
perplexity -a $arpa -t 1 -X $dir/mb.txt $d $ppl
;;
aff)
printf "^<s>\n+$" > $dir/mb.txt
perplexity -a $arpa -t 1 -X $dir/mb.txt $d $ppl
;;
wma)
printf "<w>" > $dir/wb.txt
perplexity -a $arpa -t 2 -W $dir/wb.txt $d $ppl
;;
word)
perplexity -a $arpa -t 1 $d $ppl
;;
*)
echo "type: $btype"
;;
esac
done
done

echo "ppl done"
