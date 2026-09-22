bindir     ?= /bin
sysconfdir ?= /etc
lua_cdir   != lua -e 'print(package.cpath:match("(.-)/%?.so;"))'

STRIP   = strip --strip-unneeded
INSTALL = install
CC      = gcc -std=gnu99
CFLAGS  = -O2 -ftrivial-auto-var-init=zero

OBJS =\
	src/b3sum.o\
	src/basename.o\
	src/blake3.o\
	src/chroot.o\
	src/dir.o\
	src/env.o\
	src/okutils.o\
	src/unix.o\

all: src/okutils.so

src/okutils.so: $(OBJS)
	$(CC) $(CFLAGS) -shared -o $@ $(OBJS)

.SUFFIXES: .c .cc .o

.c.o:
	$(CC) $(CFLAGS) -fpic -o $@ -c $<

install: install-strip
install-strip: all
	$(STRIP) src/okutils.so
	$(INSTALL) -m 755 src/okutils.so       $(lua_cdir)
	$(INSTALL) -m 755 scripts/main.lua     $(bindir)/okpkg
	$(INSTALL) -m 644 scripts/config.lua   $(sysconfdir)/okpkg.conf

uninstall:
	rm -f $(lua_cdir)/okutils.so 
	rm -f $(bindir)/okpkg 
	rm -f $(sysconfdir)/okpkg.conf

clean:
	find . -name \*~   -delete
	find . -name \*.so -delete
	find . -name \*.o  -delete
