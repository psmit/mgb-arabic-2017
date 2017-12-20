#!/bin/bash
#SBATCH -p coin,short-ivb,short-wsm,short-hsw,batch-hsw,batch-wsm,batch-ivb
#SBATCH -t 4:00:00
#SBATCH -n 1
#SBATCH --cpus-per-task=20
#SBATCH -N 1
#SBATCH --mem-per-cpu=11G
#SBATCH -o log/score_combine-%j.out
#SBATCH -e log/score_combine-%j.out


# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# THIS CODE IS PROVIDED *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY IMPLIED
# WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR PURPOSE,
# MERCHANTABLITY OR NON-INFRINGEMENT.
# See the Apache 2 License for the specific language governing permissions and
# limitations under the License.


# Script for system combination using minimum Bayes risk decoding.
# This calls lattice-combine to create a union of lattices that have been 
# normalized by removing the total forward cost from them. The resulting lattice
# is used as input to lattice-mbr-decode. This should not be put in steps/ or 
# utils/ since the scores on the combined lattice must not be scaled.

# begin configuration section.
cmd="run.pl --max-jobs-run 10"
min_lmwt=7
max_lmwt=17
lat_weights=
wip=0.0
#end configuration section.

echo "$0 $@"
help_message="Usage: "$(basename $0)" [options] <data-dir> <graph-dir|lang-dir> <decode-dir1> <decode-dir2> [decode-dir3 ... ] <out-dir>
Options:
  --cmd (run.pl|queue.pl...)      # specify how to run the sub-processes.
  --min-lmwt INT                  # minumum LM-weight for lattice rescoring 
  --max-lmwt INT                  # maximum LM-weight for lattice rescoring
  --lat-weights STR               # colon-separated string of lattice weights
";

[ -f ./path.sh ] && . ./path.sh
. parse_options.sh || exit 1;

if [ $# -lt 5 ]; then
  printf "$help_message\n";
  exit 1;
fi

data=$1
graphdir=$2
odir=${@: -1}  # last argument to the script
shift 2;
decode_dirs=( $@ )  # read the remaining arguments into an array
unset decode_dirs[${#decode_dirs[@]}-1]  # 'pop' the last argument which is odir
num_sys=${#decode_dirs[@]}  # number of systems to combine

symtab=$graphdir/words.txt
[ ! -f $symtab ] && echo "$0: missing word symbol table '$symtab'" && exit 1;
#[ ! -f $data/text ] && echo "$0: missing reference '$data/text'" && exit 1;


ref_filtering_cmd="cat"
[ -x local/wer_output_filter ] && ref_filtering_cmd="local/wer_output_filter"
[ -x local/wer_ref_filter ] && ref_filtering_cmd="local/wer_ref_filter"
hyp_filtering_cmd="cat"
[ -x local/wer_output_filter ] && hyp_filtering_cmd="local/wer_output_filter"
[ -x local/wer_hyp_filter ] && hyp_filtering_cmd="local/wer_hyp_filter"


function normalise {
inFile=$1
outFile=$2
paste -d ' ' <(cat $inFile | cut -d ' ' -f1) <(cat $inFile  | cut -d ' ' -f2- | perl -pe 's/[><|]/A/g;s/p/h/g;s/Y/y/g;') > $outFile
}

mkdir -p $odir/scoring

# we will use the data where all transcribers marked as non-overlap speech    
cat $data/mrwer-* | awk '{print $1}' | sort | uniq -c  | grep " $(ls -1 $data/mrwer-* | wc -l) "  | awk '{print $2}'  | sort -u > $odir/scoring/id.common
for x in  $data/mrwer-*; do
  utils/filter_scp.pl $odir/scoring/id.common $x > $odir/scoring/$(basename $x).common
#  grep -f $dir/scoring_mrwer/id.common $x > $dir/scoring_mrwer/$(basename $x).common  
  normalise $odir/scoring/$(basename $x).common $odir/scoring/$(basename $x).norm
done

mkdir -p $odir/log

for i in `seq 0 $[num_sys-1]`; do
  model=${decode_dirs[$i]}/../../final.mdl  # model one level up from decode dir
  for f in $model ${decode_dirs[$i]}/lat.1.gz ; do
    [ ! -f $f ] && echo "$0: expecting file $f to exist" && exit 1;
  done
  lats[$i]="\"ark:gunzip -c ${decode_dirs[$i]}/lat.*.gz | lattice-add-penalty --word-ins-penalty=$wip ark:- ark:- |\""
done

mkdir -p $odir/scoring/log

#cat $data/text | sed 's:<NOISE>::g' | sed 's:<SPOKEN_NOISE>::g' \
#  > $odir/scoring/test_filt.txt

$cmd LMWT=$min_lmwt:$max_lmwt $odir/log/combine_lats.LMWT.log \
  lattice-combine --inv-acoustic-scale=LMWT ${lats[@]} ark:- \| \
  lattice-mbr-decode --word-symbol-table=$symtab ark:- ark,t:- \| \
  tee $odir/scoring/LMWT.tra \| \
  utils/int2sym.pl -f 2- $symtab \| \
  $hyp_filtering_cmd \| tee $odir/scoring/LMWT.txt \| \
  utils/filter_scp.pl $odir/scoring/id.common '>' $odir/scoring/LMWT.txt.common || exit 1;

for f in $odir/scoring/*.txt; do
  normalise ${f}.common ${f}.norm
done

$cmd LMWT=$min_lmwt:$max_lmwt $odir/scoring/log/score.LMWT.log \
  common/mrwer.py $odir/scoring/mrwer-*.norm $odir/scoring/LMWT.txt.norm \
  ">" $odir/mrwer_LMWT_all || exit 1;

for j in $(seq $min_lmwt $max_lmwt); do
  line=$(grep "MR-WER" $odir/mrwer_${j}_all)
  echo "%WER $(echo $line | cut -f2 -d' ' | cut -f2 -d':') $line" > $odir/mrwer_${j}
done 

for lmwt in $(seq $min_lmwt $max_lmwt); do
  # adding /dev/null to the command list below forces grep to output the filename
  grep -a WER $odir/mrwer_${lmwt} /dev/null
done | utils/best_wer.sh  >& $odir/scoring/best_mrwer || exit 1

exit 0
