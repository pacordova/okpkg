bindir     ?= /bin
sysconfdir ?= /etc

STRIP	 = /bin/strip --strip-unneeded
INSTALL  = /bin/install
CC       = /bin/gcc
CXX      = /bin/g++
CFLAGS   = -march=native -O2 -std=gnu99
CXXFLAGS = -march=native -O2 -std=c++17

LUA_PATH  != lua -e "print(package.path:match('(.-)/%?.lua;'))"
LUA_CPATH != lua -e "print(package.cpath:match('(.-)/%?.so;'))"

OBJS =\
	src/okutils.o\
	src/b3sum.o\
	src/blake3.o\
	src/chroot.o\
	src/basename.o\
	src/unix.o\
	src/fs.o\
	src/setenv.o\


all: src/okutils.so
src/okutils.so: $(OBJS)
	$(CXX) $(CXXFLAGS) -shared -o $@ $(OBJS)
	$(STRIP) $@

.SUFFIXES: .c .cc .o

.c.o:
	$(CC) $(CFLAGS) -fpic -o $@ -c $<

.cc.o:
	$(CXX) $(CXXFLAGS) -fpic -o $@ -c $<


install: install-strip
install-strip: all
	$(STRIP) src/okutils.so
	$(INSTALL) -m 755 src/okutils.so     $(LUA_CPATH)
	$(INSTALL) -m 755 scripts/main.lua   $(bindir)/okpkg
	$(INSTALL) -m 644 scripts/config.lua $(sysconfdir)/okpkg.conf

uninstall:
	rm -f $(bindir)/bin/okpkg
	rm -f $(LUA_CPATH)/okutils.so

clean:
	find . -name \*~   -delete
	find . -name \*.so -delete
	find . -name \*.o  -delete

fmt:
	clang-format --style=file -i src/*.c -i src/*.cc
