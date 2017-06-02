#!/bin/bash

echo "$0 $@"  # Print the command line for logging
export LC_ALL=C

min_seg_len=1.55


[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 1 ]; then
   echo "usage: train_am.sh lex_suf"
   exit 1;
fi

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.


train_cmd="srun run.pl"
base_cmd=$train_cmd
decode_cmd=$train_cmd

. common/slurm_dep_graph.sh

JOB_PREFIX=$(cat id)_

function error_exit {
    echo "$1" >&2
    exit "${2:-1}"
}

#rm -Rf data mfcc
mkdir -p tmp

lsuf=_$1
#lex_name="lexicon"
#if [ -f definitions/lexicon ]; then
#  lex_name=$(cat definitions/lexicon)
#fi
#ln -s ../data-prep/${lex_name}/ data/lexicon


#job make_lex 1 4 make_subset -- common/make_dict.sh data/train/vocab data/dict
#job make_lang 1 4 make_lex -- utils/prepare_lang.sh --position-dependent-phones true data/dict "<UNK>" data/lang/local data/lang

. definitions/best_model

# Make short dir
jprev="NONE"
numjobs=20

# Train basic iterations
SLURM_EXTRA_ARGS="-c ${numjobs}"
job tra_mono 1 4 $jprev \
 -- steps/train_mono.sh --boost-silence 1.25 --nj ${numjobs} --cmd "$train_cmd" data/train_10kshort data/lang${lsuf} exp/mono${lsuf}

job ali_mono 1 4 LAST \
 -- steps/align_si.sh --boost-silence 1.25 --nj ${numjobs} --cmd "$train_cmd" data/train_wmer0 data/lang${lsuf} exp/mono${lsuf} exp/mono${lsuf}_ali

job tra_tri1 1 6 LAST \
 -- steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" $tri1_leaves $tri1_gauss data/train_wmer0 data/lang${lsuf} exp/mono${lsuf}_ali exp/tri1${lsuf}

job ali_tri1 1 4 LAST \
 -- steps/align_si.sh --nj ${numjobs} --cmd "$train_cmd" data/train_wmer0 data/lang${lsuf} exp/tri1${lsuf} exp/tri1${lsuf}_ali

job tra_tri2 1 6 LAST \
 -- steps/train_lda_mllt.sh --cmd "$train_cmd" --splice-opts "--left-context=3 --right-context=3" $tri2_leaves $tri2_gauss data/train_wmer0 data/lang${lsuf} exp/tri1${lsuf}_ali exp/tri2${lsuf}

job ali_tri2 1 4 LAST \
 -- steps/align_si.sh  --nj ${numjobs} --cmd "$train_cmd"  data/train_wmer0 data/lang${lsuf} exp/tri2${lsuf} exp/tri2${lsuf}_ali

job tra_tri3 1 6 LAST \
 -- steps/train_sat.sh --cmd "$train_cmd" $tri3_leaves $tri3_gauss data/train_wmer0 data/lang${lsuf} exp/tri2${lsuf}_ali exp/tri3${lsuf}

job ali_tri3 1 4 LAST \
 -- steps/align_fmllr.sh  --nj ${numjobs} --cmd "$train_cmd"  data/train_wmer0 data/lang${lsuf} exp/tri3${lsuf} exp/tri3${lsuf}_ali

SLURM_EXTRA_ARGS=""
# Create a cleaned version of the model, which is supposed to be better for
job clean 2 4 tra_tri3 \
 -- steps/cleanup/clean_and_segment_data.sh --nj 750 --cmd "slurm.pl --mem 2G" data/train data/lang${lsuf} exp/tri3${lsuf} exp/tri3${lsuf}_cleaned_work data/train${lsuf}_cleaned

SLURM_EXTRA_ARGS="-c ${numjobs}"
job ali_tri3_cleaned 2 4 LAST \
 -- steps/align_fmllr.sh --nj ${numjobs} --cmd "$train_cmd" data/train${lsuf}_cleaned data/lang${lsuf} exp/tri3${lsuf} exp/tri3${lsuf}_ali_cleaned

job tra_tri3_cleaned 2 6 LAST \
 -- steps/train_sat.sh --cmd "$train_cmd" $tri3_leaves $tri3_gauss data/train${lsuf}_cleaned data/lang${lsuf} exp/tri3${lsuf}_ali_cleaned exp/tri3${lsuf}_cleaned



