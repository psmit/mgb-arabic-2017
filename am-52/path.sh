#!/bin/bash

export PYTHONIOENCODING='utf-8'
export PATH="$PWD/utils:$PWD:$PATH"
module purge
module load kaldi52/2017.05.27-c9d7ccf-GCC-5.4.0-mkl phonetisaurus anaconda3 anaconda2 srilm mitlm Morfessor sph2pipe variKN m2m-aligner openfst/1.6.2-GCC-5.4.0
#module save digitala
#module load kaldi/2017.02.21-8c77d2c-GCC-5.4.0-mkl phonetisaurus/2017.02.11-4bdffc5 anaconda3 srilm mitlm Morfessor openfst/1.6.1-GCC-5.4.0 sph2pipe variKN m2m-aligner anaconda2 MorfessorJoint et-g2p
#module load kaldi/2017.02.07-c747ed5-intel-2017.1.132-mkl phonetisaurus anaconda3 srilm mitlm Morfessor openfst/1.4.1-intel-2017.1.132 sph2pipe variKN m2m-aligner anaconda2 MorfessorJoint et-g2p 
#module save is2017
#module restore digitala

module list

export THEANO_FLAGS='floatX=float32,device=cpu,force_device=true'
#source activate theanolm
