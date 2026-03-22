$(shell mkdir -p index)

prefix     := /usr
sysconfdir := /etc
bindir     := $(prefix)/bin
libdir     := $(shell lua -e "print(package.cpath:match('(.-)/%?.so;'))")

CC      := /usr/bin/gcc -std=gnu99
CFLAGS  := -O2 -fpic -shared -pipe 
CFLAGS  += $(shell pkgconf --cflags lua)
LDFLAGS := $(shell pkgconf --libs libcrypto)

all: okutils.so

okutils.so: okutils.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)
	strip --strip-unneeded $@

install: okutils.so
	mkdir -p $(DESTDIR){$(bindir),$(libdir)}
	mv -f okutils.so $(DESTDIR)$(libdir)
	cp -f main.lua   $(DESTDIR)$(bindir)/okpkg
	cp -f okpkg.conf $(DESTDIR)$(sysconfdir)

uninstall: clean
	rm -f $(DESTDIR)$(prefix)/bin/okpkg
	rm -f $(DESTDIR)$(prefix)$(LUA_CPATH)/okutils.so

clean:
	find . -name \*~   -delete
	find . -name \*.so -delete
