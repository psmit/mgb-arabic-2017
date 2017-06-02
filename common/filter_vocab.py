#!/usr/bin/env python3

import fileinput

allowed = set("AwyltnmrbhsfdkEqH>j$pzTSxg<Dv}*Y'Z&|a{V")
for line in fileinput.input():
    word = line.strip()
    if all(c in allowed for c in word):
        print(word)

