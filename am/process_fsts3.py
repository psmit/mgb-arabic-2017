#!/usr/bin/env python2
from __future__ import print_function
import pywrapfst as fst
import sys

def read_fst(inp):
    compiler = fst.Compiler(keep_state_numbering=True)
    while True:
        key = inp.readline().strip()
        if len(key) == 0:
            return
        while True:
            line = inp.readline()
            if len(line.strip()) == 0:
                break
            parts = line.split()
            if len(parts) > 3:
                num_states = sum(1 for p in parts[3].split(',')[2].split('_') if len(p) > 0)
    #            print("num states: {}".format(num_states))
                parts = parts[:3] + [parts[2], str(num_states)]
            if len(parts) == 2:
                parts = parts[:1]
            print(" ".join(parts), file=compiler)
        yield key, compiler.compile()

for key, f in read_fst(sys.stdin):
    # f.topsort()
    # final_lens = []
    # time = [None] * f.num_states()
    # time[0] = 0
    # for s in f.states():
    #     assert time[s] is not None
    #     for a in f.arcs(s):
    #         nt = time[s] + int(a.weight.to_string())
    #         assert time[a.nextstate] is None or time[a.nextstate] == nt
    #         time[a.nextstate] = nt
    #     if f.final(s) != fst.Weight.Zero(f.weight_type()):
    #         final_lens.append(time[s])
    # state_list = []
    # degrees = []
    # T = max(final_lens)+1
    # for _ in range(T):
    #     state_list.append([])
    #     degrees.append([])
    #
    # for s in f.states():
    #     state_list[time[s]].append(s)
    #     degrees[time[s]].append(f.num_arcs(s))
    #
    # print("{} {} {} {} {}".format(key, T, sum(1 for s in state_list if len(s) == 0), max(len(s) for s in state_list), max(max(d) for d in degrees if len(d) > 0)))
    # for t in range(T):
    #     print("{} {} {} {} {}".format(t, len(state_list[t]), min(degrees[t]) if len(degrees[t]) > 0 else 0, max(degrees[t]) if len(degrees[t]) > 0 else 0, sum(degrees[t])/len(degrees[t]) if len(degrees[t]) > 0 else 0))
    # print()
    # #print(" ".join(str(s) for s in f.states()))
    # #print(" ".join(str(s) for s in range(f.num_states())))
    # assert " ".join(str(s) for s in f.states()) == " ".join(str(s) for s in range(f.num_states()))
    #assert f.properties(fst.ACYCLIC, False) > 0
    #assert f.properties(fst.NOT_TOP_SORTED, False)  == 0
    p = f.properties(fst.NOT_TOP_SORTED | fst.TOP_SORTED, False)
    print("TOPSORT")
    print (p)
    print(p & fst.NOT_TOP_SORTED)
    print(p & fst.TOP_SORTED)
    print()

#    print("{} {} {}".format(key, min(final_lens), max(final_lens)))
    #print("{} {} {}".format(key, f.num_states(), sum( f.num_arcs(s) for s in f.states())))
#    print("{} {}".format(key, max(int(x.to_string()) for x in fst.shortestdistance(f))))
#    print("{} {}".format(key, max(int(x.to_string()) for x in fst.shortestdistance(f,reverse=True))))
#    print("{} {}".format(key, int(fst.shortestdistance(f, reverse=True)[0].to_string())))

