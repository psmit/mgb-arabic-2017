#!/usr/bin/env python3
import fileinput
import re
r = re.compile('^ngram ([0-9]+)=')

for line in fileinput.input():
    if line.startswith('\\81-grams:'):
        print('\\end\\')
        break
    if line.startswith('ngram'):
        m = r.match(line)
        if m is not None:
            if int(m.group(1)) > 80:
                continue
    print(line.strip())
