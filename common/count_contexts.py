#!/usr/bin/env python3

import sys

contexts = 0
for line in sys.stdin.buffer:
    if line.startswith(b'ngram'):
        contexts += int(line.strip().split(b'=')[1]) 
    elif b'gram' in line:
        break

print("{}".format(contexts))
