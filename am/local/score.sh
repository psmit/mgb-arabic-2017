#!/usr/bin/bash

dir=""
ok=true
for d in "$@"; do
    if ! $ok; then
      ok=true
      continue
    fi
    if [[ $d == --* ]]; then
        ok=false
        continue
    fi
   dir=$d
   break
done

echo $dir

if [ -f $dir/text ]; then
steps/scoring/score_kaldi_wer.sh "$@"
steps/scoring/score_kaldi_cer.sh --stage 2 "$@"
fi

if [ -f $dir/mrwer-1 ]; then
common/score_mrwer.sh "$@"
fi
