# mgb-arabic-2017

All the acoustic models are build from the directory "am", the language models are build from the directory "lm".

The steps I took to build the models are:

- Run `kaldi_prep.py ar-mgb2016 train am/train` and `kaldi_prep.py ar-mgb2016 train_wmer0 am/train_wmer0`. (kaldi_prep.py comes from https://github.com/psmit/kaldi-prep )
- Train GMM acoustic models with `common/train_am.sh`
- Train BLSTM DNN with:
  - `common/train_chain_dataprep.sh gr`
  - `common/train_chain_prep.sh gr_tdnn_blstm_9`
  - `common/train_chain_model.sh gr_tdnn_blstm_9_a`
  - run `common/train_chain_extra_dataset.sh` for dev/test set
- Train vari-gram LM in the `lm` directory
  - create files `mgb2/mgb2.xz`, `mgb2/devel-mgb2.xz` and `devel-egy.xz` with in the first the lm training data (buckwalter) and in the latter 2 the dev transcriptions for mgb-2 and egy (I can't find anymore the scripts that did this)
  - create some directories, e.g. `mgb2/chars`, `mgb2/morfessor_f2_a0.1_tokens`, `mgb2/word_f1`. These directories contain the parameters in their filename. f2 is a frequency threshold of 2, a0.1 is a morfessor alpha of 0.1.
  - Run `common/run_morph_job.sh mgb2/morfessor_f2_a0.1_tokens` or `common/run_char_job.sh mgb2/chars` or `common/run_word_job.sh mgb2/word_f1`. For Morfessor, I think you also had to run `common/run_morphseg_job_dev.sh` and `common/run_morphseg_job.sh`
  - Make directories like `varik_aff` / `varik_pre` / `varik_suf` / `varik_wma` in the char of morfessor directories and `varik_word` in the word directory. "aff" is left-right marked, "pre" is left-marked, "suf" is right-marked, "wma" is word boundary marker
  - On these varik* directories, run `common/run_prep_dev.sh` and `common/run_prep_varikn.sh` before running `common/train_varikn_background.sh`. varigram_kn must be on the path (https://github.com/vsiivola/variKN)
- Once a small arpa is created, put it in `am/data/lm/MODEL_NAME/small/arpa` and put "aff" "word" "suf"  "pre" "wma" in am/data/lm/MODEL_NAME/type
- Run from `am` the command `common/process_lm.sh MODEL_NAME gr` if it all works it puts a lexicon-fst modified lang directory in `data/recog_langs_gr/MODEL_NAME
  
Other interesting script:
- `common/train_adap_nnet3.sh`: The script used to adapt the acoustic model to Egyptian

For myself, I keep the following guidelines for a varikn model:
- For first pass, it should have between 4M and 8M n-grams, for second pass it can be as big as you can train the model. Examples of sizes for different varikn parameters:
```  
  61097228 lm/mgb2/morfessor_f2_a0.01_tokens/varik_aff/arpa-mgb2-0.0005 <- rescore model
  45614982 lm/mgb2/morfessor_f2_a0.01_tokens/varik_aff/arpa-mgb2-0.005
  36084520 lm/mgb2/morfessor_f2_a0.01_tokens/varik_aff/arpa-mgb2-0.01
  22993918 lm/mgb2/morfessor_f2_a0.01_tokens/varik_aff/arpa-mgb2-0.02
   7291900 lm/mgb2/morfessor_f2_a0.01_tokens/varik_aff/arpa-mgb2-0.05 <- Ideal for small
   3422667 lm/mgb2/morfessor_f2_a0.01_tokens/varik_aff/arpa-mgb2-0.08
   2401364 lm/mgb2/morfessor_f2_a0.01_tokens/varik_aff/arpa-mgb2-0.1
   ```
   
   
