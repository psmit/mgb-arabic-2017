#!/usr/bin/env python3

import sys

segments = []
trans = {}
for line in open(sys.argv[1], encoding='utf-8'):
    parts = line.split()
    assert len(parts) == 4
    segments.append(tuple(parts))
    trans[parts[0]] = []
    

for line in sys.stdin:
    parts = line.split()
    fk = parts[0]
    t = float(parts[2])
    text = parts[4]
    for s in segments:
        if s[1] == fk and float(s[2]) < t < float(s[3]):
            trans[s[0]].append((t, text))

for key, tran in trans.items():
     print("{} {}".format(key, " ".join(t[1] for t in sorted(tran, key=lambda x: x[0]))))
    
            

