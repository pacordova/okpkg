bindir     ?= /bin
sysconfdir ?= /etc

CC       = /bin/gcc
CXX      = /bin/g++
CXXV    != $(CXX) -dumpversion
CXXM    != $(CXX) -dumpmachine
CFLAGS   = -O2 -std=gnu99
CXXFLAGS = -O2
LDFLAGS  = -lcrypto

LUA_PATH  != lua -e "print(package.path:match('(.-)/%?.lua;'))"
LUA_CPATH != lua -e "print(package.cpath:match('(.-)/%?.so;'))"

objs = src/basename.o src/chdir.o src/chroot.o src/mkdir.o src/okutils.o \
       src/pwd.o src/setenv.o src/sha3sum.o src/symlink.o src/remove_all.o \
       src/exists.o src/directory_iterator.o
       
src/okutils.so: $(objs)
	$(CXX) $(CXXFLAGS) -shared -o $@ src/*.o $(LDFLAGS)

.SUFFIXES: .c .o
.c.o:
	$(CC) $(CFLAGS) -fpic -o $@ -c $<

.SUFFIXES: .cc .o
.cc.o:
	$(CXX) $(CXXFLAGS) -fpic -o $@ -c $<

install: install-strip
install-strip: src/okutils.so
	strip --strip-unneeded $<
	mkdir -p $(bindir) $(LUA_CPATH)
	mv -f $< $(LUA_CPATH)
	cp -f scripts/main.lua $(bindir)/okpkg
	cp -f scripts/config.lua $(sysconfdir)/okpkg.conf

uninstall: clean
	rm -f $(bindir)/bin/okpkg
	rm -f $(LUA_CPATH)/okutils.so

clean:
	find . -name \*~   -delete
	find . -name \*.so -delete
	find . -name \*.o  -delete

fmt:
	clang-format --style=file -i src/*.c -i src/*.cc
