#!/bin/bash
# Copyright 2012-2014  Johns Hopkins University (Author: Daniel Povey, Yenda Trmal)
# Apache 2.0

# See the script steps/scoring/score_kaldi_cer.sh in case you need to evalutate CER

[ -f ./path.sh ] && . ./path.sh

# begin configuration section.
cmd=run.pl
stage=0
decode_mbr=false
stats=true
beam=6
word_ins_penalty=0.0,0.5,1.0
min_lmwt=7
max_lmwt=17
iter=final
#end configuration section.

echo "$0 $@"  # Print the command line for logging
[ -f ./path.sh ] && . ./path.sh
. parse_options.sh || exit 1;

if [ $# -ne 3 ]; then
  echo "Usage: $0 [--cmd (run.pl|queue.pl...)] <data-dir> <lang-dir|graph-dir> <decode-dir>"
  echo " Options:"
  echo "    --cmd (run.pl|queue.pl...)      # specify how to run the sub-processes."
  echo "    --stage (0|1|2)                 # start scoring script from part-way through."
  echo "    --decode_mbr (true/false)       # maximum bayes risk decoding (confusion network)."
  echo "    --min_lmwt <int>                # minumum LM-weight for lattice rescoring "
  echo "    --max_lmwt <int>                # maximum LM-weight for lattice rescoring "
  exit 1;
fi

data=$1
lang_or_graph=$2
dir=$3

symtab=$lang_or_graph/words.txt

for f in $symtab $dir/lat.1.gz $data/mrwer-1; do
  [ ! -f $f ] && echo "score.sh: no such file $f" && exit 1;
done


ref_filtering_cmd="cat"
[ -x local/wer_output_filter ] && ref_filtering_cmd="local/wer_output_filter"
[ -x local/wer_ref_filter ] && ref_filtering_cmd="local/wer_ref_filter"
hyp_filtering_cmd="cat"
[ -x local/wer_output_filter ] && hyp_filtering_cmd="local/wer_output_filter"
[ -x local/wer_hyp_filter ] && hyp_filtering_cmd="local/wer_hyp_filter"


if $decode_mbr ; then
  echo "$0: scoring with MBR, word insertion penalty=$word_ins_penalty"
else
  echo "$0: scoring with word insertion penalty=$word_ins_penalty"
fi

function normalise {
inFile=$1
outFile=$2
paste -d ' ' <(cat $inFile | cut -d ' ' -f1) <(cat $inFile  | cut -d ' ' -f2- | perl -pe 's/[><|]/A/g;s/p/h/g;s/Y/y/g;') > $outFile
}

mkdir -p $dir/scoring_mrwer

# we will use the data where all transcribers marked as non-overlap speech    
cat $data/mrwer-* | awk '{print $1}' | sort | uniq -c  | grep " $(ls -1 $data/mrwer-* | wc -l) "  | awk '{print $2}'  | sort -u > $dir/scoring_mrwer/id.common
for x in  $data/mrwer-*; do
  utils/filter_scp.pl $dir/scoring_mrwer/id.common $x > $dir/scoring_mrwer/$(basename $x).common
#  grep -f $dir/scoring_mrwer/id.common $x > $dir/scoring_mrwer/$(basename $x).common  
  normalise $dir/scoring_mrwer/$(basename $x).common $dir/scoring_mrwer/$(basename $x).norm
done


#cat $data/text | $ref_filtering_cmd > $dir/scoring_mrwer/test_filt.txt || exit 1;
if [ $stage -le 0 ]; then

  for wip in $(echo $word_ins_penalty | sed 's/,/ /g'); do
    mkdir -p $dir/scoring_mrwer/penalty_$wip/log

    if $decode_mbr ; then
      $cmd LMWT=$min_lmwt:$max_lmwt $dir/scoring_mrwer/penalty_$wip/log/best_path.LMWT.log \
        acwt=\`perl -e \"print 1.0/LMWT\"\`\; \
        lattice-scale --inv-acoustic-scale=LMWT "ark:gunzip -c $dir/lat.*.gz|" ark:- \| \
        lattice-add-penalty --word-ins-penalty=$wip ark:- ark:- \| \
        lattice-prune --beam=$beam ark:- ark:- \| \
        lattice-mbr-decode  --word-symbol-table=$symtab \
        ark:- ark,t:- \| \
        utils/int2sym.pl -f 2- $symtab \| \
        $hyp_filtering_cmd '>' $dir/scoring_mrwer/penalty_$wip/LMWT.txt || exit 1;

    else
      $cmd LMWT=$min_lmwt:$max_lmwt $dir/scoring_mrwer/penalty_$wip/log/best_path.LMWT.log \
        lattice-scale --inv-acoustic-scale=LMWT "ark:gunzip -c $dir/lat.*.gz|" ark:- \| \
        lattice-add-penalty --word-ins-penalty=$wip ark:- ark:- \| \
        lattice-best-path --word-symbol-table=$symtab ark:- ark,t:- \| \
        utils/int2sym.pl -f 2- $symtab \| \
        $hyp_filtering_cmd \| tee $dir/scoring_mrwer/penalty_$wip/LMWT.txt \| \
        utils/filter_scp.pl $dir/scoring_mrwer/id.common '>' $dir/scoring_mrwer/penalty_$wip/LMWT.txt.common || exit 1;
        #grep -f $dir/scoring_mrwer/id.common '>' $dir/scoring_mrwer/penalty_$wip/LMWT.txt.common || exit 1;
    fi

    for f in $dir/scoring_mrwer/penalty_$wip/*.txt; do
      normalise ${f}.common ${f}.norm
    done

    $cmd LMWT=$min_lmwt:$max_lmwt $dir/scoring_mrwer/penalty_$wip/log/score.LMWT.log \
      common/mrwer.py $dir/scoring_mrwer/mrwer-*.norm $dir/scoring_mrwer/penalty_$wip/LMWT.txt.norm \
      ">" $dir/mrwer_LMWT_${wip}_all || exit 1;

    for j in $(seq $min_lmwt $max_lmwt); do
      line=$(grep "MR-WER" $dir/mrwer_${j}_${wip}_all)
      echo "%WER $(echo $line | cut -f2 -d' ' | cut -f2 -d':') $line" > $dir/mrwer_${j}_${wip}
    done 
    
  done
fi

for wip in $(echo $word_ins_penalty | sed 's/,/ /g'); do
    for lmwt in $(seq $min_lmwt $max_lmwt); do
      # adding /dev/null to the command list below forces grep to output the filename
      grep -a WER $dir/mrwer_${lmwt}_${wip} /dev/null
    done
  done | utils/best_wer.sh  >& $dir/scoring_mrwer/best_mrwer || exit 1

