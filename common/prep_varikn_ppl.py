#!/usr/bin/env python3

import logging
import sys
import os
import lzma

import morfessor

def parse_name(d):
    base = os.path.basename(d)
    assert base.startswith("varik")
    parts = base.split('_')
    dataset = parts[0]
    btype = parts[1]
    return btype

def main(d,tmp):
    btype = parse_name(d)
    
    word_map = os.path.join(os.path.dirname(d),'wordmap')
    word_map_devel = os.path.join(os.path.dirname(d),'wordmap_devel')

    top_level= os.path.dirname(os.path.dirname(d)) 
    
    devdata = os.path.join(top_level, 'devel.xz')
    dev_files = []
    for f in os.listdir(top_level):
        if f.startswith('devel') and f.endswith(".xz"):
            dev_files.append(os.path.join(top_level, f))

    between = " "
    prefix = ""
    suffix = ""
   
    assert btype in {"word", "aff", "wma", "suf", "pre"}
    if btype == "wma":
        between = " <w> "
    if btype == "pre" or btype == "aff":
        prefix ="+"
    if btype == "suf" or btype == "aff":
        suffix ="+"
    if btype != "word":
        if os.path.exists(os.path.join(os.path.dirname(d), 'model.bin')):
            morf = morfessor.MorfessorIO().read_any_model(os.path.join(os.path.dirname(d), 'model.bin'))
        else:
            morf = None
    else:
        morf = None
    m = {}
    for line in open(word_map, encoding='utf-8'):
        parts = line.strip().split()
        m[parts[0]] = "{} {}".format(suffix,prefix).join(parts[1:]).replace("+<unk>","<unk>").replace("<unk>+", "<unk>").replace("+<UNK>","<UNK>").replace("<UNK>+", "<UNK>").replace("<unk>", "<UNK>")
    

    if os.path.isfile(word_map_devel):
        for line in open(word_map_devel, encoding='utf-8'):
            parts = line.strip().split()
            m[parts[0]] = "{} {}".format(suffix,prefix).join(parts[1:]).replace("+<unk>","<unk>").replace("<unk>+", "<unk>").replace("+<UNK>","<UNK>").replace("<UNK>+", "<UNK>").replace("<unk>", "<UNK>")
    for dfile in dev_files:
        with open(os.path.join(d, os.path.basename(dfile)[:-3]), 'w', encoding='utf-8') as outf:
            for line in lzma.open(dfile, 'rt', encoding='utf-8'):
                parts = line.strip().split()
                for p in parts:
                    if p not in m or "<UNK>" in m[p]:
                        if btype == "word":
                             m[p] = "<UNK>"
                        else:
                            if morf is not None:
                                morphs = morf.viterbi_segment(p)[0] 
                            else:
                                morphs = list(p)
                            m[p] = "{} {}".format(suffix,prefix).join(morphs)
                new_line = between + between.join(m[p] for p in parts) + between
                new_line = new_line.strip()
                if not new_line.startswith("<s>"):
                    new_line = "<s> " + new_line
                if not new_line.endswith("</s>"):
                    new_line = new_line + " </s>" 
                print(new_line.strip(), file=outf)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    main(sys.argv[1], None)
