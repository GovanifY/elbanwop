elbanwop
====================
BIN400 challenge released at Hack In The Box Amsterdam 2017 CTF.
Implements a small virtual machine in pure ROP. A reverse-pwnable
so to speak. You get a vulnerable binary, and an input that pwns the
binary and implements the crackme/reverseme. :-)

Dependencies
====================

* gcc
* python
* [ropstone](https://github.com/blasty/ropstone)

Building
====================

```
$ make
```


Running
====================

```
$ ./vuln input.bin
```

Credits
====================

blasty <<peter@haxx.in>>
