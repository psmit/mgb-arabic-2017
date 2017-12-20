#!/usr/bin/env python3

import fileinput

_unicode = u"\u0622\u0624\u0626\u0628\u062a\u062c\u06af\u062e\u0630\u0632\u0634\u0636\u0638\u063a\u0640\u0642\u0644\u0646\u0648\u064a\u064c\u064e\u0650\u0652\u0670\u067e\u0686\u0621\u0623\u0625\u06a4\u0627\u0629\u062b\u062d\u062f\u0631\u0633\u0635\u0637\u0639\u0641\u0643\u0645\u0647\u0649\u064b\u064d\u064f\u0651\u0671"
_buckwalter = u"|&}btjGx*z$DZg_qlnwyNaio`PJ'><VApvHdrsSTEfkmhYFKu~{"

_forwardMap = {ord(a):b for a,b in zip(_unicode, _buckwalter)}
_backwardMap = {ord(b):a for a,b in zip(_unicode, _buckwalter)}

def toBuckWalter(s):
  return s.translate(_forwardMap)

def fromBuckWalter(s):
  return s.translate(_backwardMap)


for line in fileinput.input():
    key, rest = line.strip().split(None, 1)
    print("{} {}".format(key, toBuckWalter(rest)))
