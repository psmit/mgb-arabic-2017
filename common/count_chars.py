#!/usr/bin/env python3

import fileinput
import collections

counter = collections.Counter()
for line in fileinput.input():
    for c in line.strip():
        counter[c] += 1

for c, count in counter.most_common():
    print("{}\t{}".format(c, count))

