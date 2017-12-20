#!/bin/bash
#SBATCH -p coin,short-ivb,short-hsw,batch-hsw,batch-ivb
#SBATCH -t 4:00:00
#SBATCH --mem-per-cpu=40G
#SBATCH -o log/fix-theano-%j.out
#SBATCH -e log/fix-theano-%j.out
echo "$0 $@"  # Print the command line for logging
beam=8
lmscale=8
tlbeam=500
tlmaxtok=100
tlrecomb=10


oldlang=$1
newlang=$2
indir=$3
outdir=$4
id=$5

. ./path.sh 
source activate theanolm
oldlm=$oldlang/G.carpa
newlm=$newlang/nnlm.h5

gunzip -c $indir/lat.${id}.gz | \
    lattice-copy --exclude=<(grep -E "seg|first" $outdir/lat.theanolm.${id} )  ark:- ark:- | \
    lattice-prune --inv-acoustic-scale=$lmscale --beam=$beam ark:- ark:- | \
      lattice-lmrescore-const-arpa --lm-scale=-1.0 ark:- "$oldlm" ark,t:- | \
      theanolm rescore --log-file $outdir/log/theano_re-rescore.${id}.log --log-level debug $newlm - $oldlang/words.txt - --lm-scale $lmscale --beam $tlbeam --max-tokens-per-node $tlmaxtok --recombination-order $tlrecomb | \
      tee  $outdir/lat.theanolm.${id}.extra | \
      cat $outdir/lat.theanolm.${id} <(echo " ") - | \
      lattice-minimize ark:- ark:- | gzip -c > $outdir/lat.${id}.gz
