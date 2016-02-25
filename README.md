It is an experimental minimal find-like command that only use POSIX shell built-in functions

Features
--------

 * mindepth
 * maxdepth
 * filter type
 * search for deadlink

Supported type
--------------

 * ! not exists (or permission denied)
 * f file
 * d directory
 * s socket
 * p pipe (FIFO)
 * b block special file
 * c character special file
 * U unknown

 * l`X` symlink of type `X`
 * l! dead [sym]link
 * lf symlink to file
 * ld symlink to directory


Sample of use
-------------

```
$ ./findlike showall tests-data
d tests-data (0)
f tests-data/-h (1)
lf tests-data/a_symlink_file (1)
d tests-data/bin (1)
f tests-data/bin/a_file (2)
d tests-data/emptydir (1)
l! tests-data/nonex (1)
lf tests-data/pass.symlink (1)
ld tests-data/x (1)
```

```
$ ./findlike showdeadlink tests-data
tests-data/nonex
```

```
$ ./findlike showdir tests-data
0 tests-data
1 tests-data/bin
1 tests-data/emptydir
1 tests-data/x
```

```
$ ./findlike showfile tests-data
1 tests-data/-h
1 tests-data/a_symlink_file
2 tests-data/bin/a_file
1 tests-data/pass.symlink
```

```
$ MINDEPTH=0 MAXDEPTH=0 ./findlike showdir tests-data
0 tests-data
```

```
$ MINDEPTH=1 MAXDEPTH=1 ./findlike showdir tests-data
1 tests-data/bin
1 tests-data/emptydir
1 tests-data/x
```

```
$ MINDEPTH=2 ./findlike showfile tests-data
2 tests-data/bin/a_file
```

```
$ MINDEPTH=3 ./findlike showfile tests-data
```

