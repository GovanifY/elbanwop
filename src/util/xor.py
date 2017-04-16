#!/usr/bin/python

import sys

data = open(sys.argv[1]).read()
xorkey = sys.argv[2]

o = ""

for i in xrange(len(data)):
    v = ord(data[i]) ^ ord(xorkey[i % len(xorkey)])
    v = v ^ 0xaa
    o += chr(v)

fn = "%s.enc" % (sys.argv[1])
fh = open(fn, "wb")
fh.write(o)
fh.close()
