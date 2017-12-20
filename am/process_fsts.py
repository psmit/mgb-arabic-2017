#!/usr/bin/env python2
from __future__ import print_function
import pywrapfst as fst
import sys

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

for key, f in read_fst(sys.stdin):
    f.topsort()
    #print("{} {} {}".format(key, f.num_states(), sum( f.num_arcs(s) for s in f.states())))
    paths = [0] * f.num_states()
    paths[0] = 1
    real_num_paths = 0
    for s in f.states():
        for a in f.arcs(s):
            paths[a.nextstate] += paths[s]
        if f.final(s) != fst.Weight.Zero(f.weight_type()):
            real_num_paths += paths[s]

    print("{} {}".format(key, real_num_paths))
