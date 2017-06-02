#!/usr/bin/env python3

import sys

for line in sys.stdin:
    parts = line.split()
    word = parts[0]
    prob = parts[1]
    phones = parts[2:]

    start = not word.startswith('+')
    end = not word.endswith('+')

    labels = ["I"] * len(phones)    
    
    if start: 
        labels[0] = "B" 
    if end:
        labels[-1] = "E"
    if len(phones) == 1 and start and end:
        labels[0] = "S"
    
    print("{} {} {}".format(word, prob, " ".join("{}_{}".format(p,l) for p,l in zip(phones,labels))))
