prefix     = /usr
sysconfdir = /etc
bindir     = $(prefix)/bin

CC = /usr/bin/gcc -std=gnu99
CXX = /usr/bin/g++
CFLAGS = -O2
LDFLAGS = -lcrypto
LUA_PATH != lua -e "print(package.path:match('(.-)/%?.lua;'))"
LUA_CPATH != lua -e "print(package.cpath:match('(.-)/%?.so;'))"


objs = src/basename.o src/chdir.o src/chroot.o src/mkdir.o src/okutils.o \
       src/pwd.o src/setenv.o src/sha3sum.o src/symlink.o src/remove_all.o \
       src/exists.o src/directory_iterator.o
       

src/okutils.so: $(objs)
	$(CXX) $(CFLAGS) -shared -o $@ src/*.o $(LDFLAGS)

.SUFFIXES: .c .o
.c.o:
	$(CC) $(CFLAGS) -fpic -o $@ -c $<

.SUFFIXES: .cc .o
.cc.o:
	$(CXX) $(CFLAGS) -fpic -o $@ -c $<

install: install-strip
install-strip: src/okutils.so
	strip --strip-unneeded $<
	mkdir -p $(DESTDIR)$(bindir) $(DESTDIR)$(LUA_CPATH)
	mv -f $< $(DESTDIR)$(LUA_CPATH)
	cp -f scripts/main.lua $(DESTDIR)$(bindir)/okpkg
	cp -f scripts/config.lua $(DESTDIR)$(sysconfdir)/okpkg.conf

uninstall: clean
	rm -f $(DESTDIR)$(prefix)/bin/okpkg
	rm -f $(DESTDIR)$(prefix)$(LUA_CPATH)/okutils.so

clean:
	find . -name \*~   -delete
	find . -name \*.so -delete
	find . -name \*.o  -delete

fmt:
	clang-format --style=file -i src/*.c -i src/*.cc
