prefix     = /usr
sysconfdir = /etc
bindir     = $(prefix)/bin

CC = /usr/bin/gcc -std=gnu99
CFLAGS = -O2
LDFLAGS = -lcrypto
LUA_CPATH != lua -e "print(package.cpath:match('(.-)/%?.so;'))"

objs = src/basename.o src/chdir.o src/chroot.o src/mkdir.o src/okutils.o \
       src/pwd.o src/setenv.o src/sha3sum.o src/symlink.o
       

src/okutils.so: $(objs)
	$(CC) $(CFLAGS) -shared -o $@ src/*.o $(LDFLAGS)

.SUFFIXES: .c .o
.c.o:
	$(CC) $(CFLAGS) -fpic -o $@ -c $<

install: install-strip
install-strip: src/okutils.so
	strip --strip-unneeded $<
	mkdir -p $(DESTDIR)$(bindir) $(DESTDIR)$(LUA_CPATH)
	mv -f $< $(DESTDIR)$(LUA_CPATH)
	cp -f main.lua $(DESTDIR)$(bindir)/okpkg
	cp -f config.lua $(DESTDIR)$(sysconfdir)/okpkg.conf
	lua init.lua

uninstall: clean
	rm -f $(DESTDIR)$(prefix)/bin/okpkg
	rm -f $(DESTDIR)$(prefix)$(LUA_CPATH)/okutils.so

clean:
	find . -name \*~   -delete
	find . -name \*.so -delete
	find . -name \*.o  -delete
