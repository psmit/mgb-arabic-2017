#!/usr/bin/env python2

from __future__ import print_function
import pywrapfst as fst
import sys

wordsfile = sys.argv[1]


st = fst.SymbolTable.read_text(wordsfile)

words_map = {}
for line in open(wordsfile):
    if len(line.strip()) == 0:
        continue
    word, i = line.strip().split()
    i = int(i)
    words_map[word] = i
   
if "<w>" in st:
    wtag = st.find("<w>")
else:
    wtag = None

def read_fst(inp):
    compiler = fst.Compiler()
    while True:
        key = inp.readline().strip()
        if len(key) == 0:
            return
        while True:
            line = inp.readline()
            if len(line.strip()) == 0:
                break
            parts = line.split()
            if len(parts) > 4:
                parts = parts[:4]
            if len(parts) == 2:
                parts = parts[:1]
            print(" ".join(parts), file=compiler)
        yield key, compiler.compile()

if "<w>" in st:
    print("Word boundary mode", file=sys.stderr)

sequences = set()
for key, f in read_fst(sys.stdin):
    boundary_states = {0}
    between_states = set()

    f.topsort()
    for s in f.states():
        for i, a in enumerate(f.arcs(s)):
            sym = st.find(a.ilabel)
            if sym == "<w>":
                boundary_states.add(a.nextstate)
            if sym.startswith('+'):
                between_states.add(s)
            if sym.endswith('+'):
                between_states.add(a.nextstate)

    if "<w>" in st:
        for i, s in enumerate(f.states()):
            if i == 0:
                boundary_states.add(s)
            if s not in boundary_states:
                between_states.add(s) 
    else:
        for s in f.states():
            if s not in between_states:
                boundary_states.add(s)

    assert len(boundary_states & between_states) == 0
    
    print("Bound: {} Between: {} Total states: {} Sum: {}".format(len(boundary_states), len(between_states), f.num_states(), len(boundary_states | between_states)), file=sys.stderr)
    
    def dfs(state, cur_seq):
        global sequences
        global f
        if f.num_arcs(state) == 0:
            sequences.add(cur_seq)
        for a in f.arcs(state):
            if a.nextstate in boundary_states:
                sequences.add(cur_seq + (a.ilabel,))
            else:
                dfs(a.nextstate, cur_seq + (a.ilabel,))

    for s in boundary_states:
        dfs(s, tuple())    

for s in sequences:
    print(" ".join(str(c) for c in s))# if c != wtag))