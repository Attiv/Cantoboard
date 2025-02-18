#!/usr/bin/env python3
import sys

tradCharsFile = open('trad-chinese-chars.txt', 'r') 
tradChars = set()
for line in tradCharsFile.readlines():
    tradChars.add(line.strip())

for line in sys.stdin:
    line = line.strip()
    hasSim = False
    for c in line:
        if c.isascii() or c == '·': continue
        hasSim = c not in tradChars
        if hasSim: break
    if not hasSim: print(line)
