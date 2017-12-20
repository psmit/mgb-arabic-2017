#!/bin/bash
#SBATCH -p coin,short-ivb,short-wsm,short-hsw,batch-hsw,batch-wsm,batch-ivb
#SBATCH -t 3:00:00
#SBATCH -n 1
#SBATCH --cpus-per-task=8
#SBATCH -N 1
#SBATCH --mem-per-cpu=6G
#SBATCH -o log/recognize-%j.out
#SBATCH -e log/recognize-%j.out

export LC_ALL=C

# Begin configuration section.
dataset=dev
skip_scoring=false
beam=20
iter=final
extra_flags=""
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# -lt 2 ]; then
   echo "usage: common/recognize.sh am_model base_lm big_lm"
   echo "e.g.:  common/recognize.sh exp/tri3 data/recog_langs/word_s_20k_2gram data/recog_langs/word_s_20k_5gram"
   echo "main options (for others, see top of script file)"

   exit 1;
fi

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

am=$1
smalllm=$2
sname=$(basename $smalllm)
mkgraph_flags=""
decode_flags=""
if [ -f ${am}/frame_subsampling_factor ]; then
mkgraph_flags="--self-loop-scale 1.0"
decode_flags="--post-decode-acwt 10.0 --acwt 1.0"
fi

#srun -n1 utils/mkgraph.sh --remove-oov $mkgraph_flags ${smalllm} ${am} ${am}/graph_${sname}

dsname=$(basename $dataset)
extra=""
if [ "$dsname" != "dev" ]; then 
extra=_$dsname
fi
if [ "$iter" != "final" ]; then
extra=${iter}${extra}
fi
if [ ! -f ${am}/decode${extra}_${sname}/wer_15_0.0 ]; then 
case $am in
  *tri[1-2])
  echo "decode a lda model"
;;
  *tri*)
   steps/decode_fmllr.sh --beam $beam --lattice-beam 10.0 --min-active 12000 --skip-scoring $skip_scoring --nj 5 --scoring-opts "--min-lmwt 4 --max-lmwt 18" ${am}/graph_${sname} data/${dataset} ${am}/decode${extra}_${sname}
;;
  *)
   steps/nnet3/decode.sh $extra_flags --iter $iter --beam $beam --lattice-beam 10.0 --min-active 12000 --skip-scoring $skip_scoring --nj 5 $decode_flags --scoring-opts "--min-lmwt 4 --max-lmwt 18" --online-ivector-dir ${am}/ivecs/ivectors_${dataset} ${am}/graph_${sname} ${am}/feats/${dataset} ${am}/decode${extra}_${sname}

;;
esac
fi

if [ ! -f ${am}/decode${extra}_${sname}_rs/wer_15_0.0 ]; then 
echo "rescore result not there yet"
echo "${smalllm}_big/G.carpa"
if [ -f ${smalllm}_big/G.carpa ]; then
echo "There is a carpa!!"
  steps/lmrescore_const_arpa.sh --scoring-opts "--min-lmwt 1 --max-lmwt 30" $smalllm ${smalllm}_big ${am}/feats/${dataset} ${am}/decode${extra}_${sname} ${am}/decode${extra}_${sname}_rs
fi
fi
