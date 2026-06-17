bindir     ?= /bin
sysconfdir ?= /etc

CC       = /bin/gcc
CXX      = /bin/g++
CFLAGS   = -march=native -O2 -std=gnu99
CXXFLAGS = -march=native -O2

LUA_PATH  != lua -e "print(package.path:match('(.-)/%?.lua;'))"
LUA_CPATH != lua -e "print(package.cpath:match('(.-)/%?.so;'))"

objs = src/basename.o src/chdir.o src/chroot.o src/mkdir.o src/okutils.o \
       src/pwd.o src/setenv.o src/symlink.o src/remove_all.o \
       src/exists.o src/directory_iterator.o src/b3sum.o
       
src/okutils.so: $(objs)
	$(CXX) $(CXXFLAGS) -shared -o $@ src/*.o

src/b3sum.o: src/b3sum.c
	$(CC) $(CFLAGS) -O3 -fpic -o $@ -c $<

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
