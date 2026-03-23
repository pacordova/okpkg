prefix     = /usr
sysconfdir = /etc
bindir     = $(prefix)/bin
libdir     = `lua -e "print(package.cpath:match('(.-)/%?.so;'))"`

CC      = /usr/bin/gcc -std=gnu99
CFLAGS  = -O2 -fpic -shared -pipe `pkgconf --cflags lua`
LDFLAGS = `pkgconf --libs libcrypto`

okutils.so: okutils.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)
	strip --strip-unneeded $@

install: okutils.so
	mkdir -p $(DESTDIR){$(bindir),$(libdir)}
	mv -f okutils.so $(DESTDIR)$(libdir)
	cp -f main.lua   $(DESTDIR)$(bindir)/okpkg
	cp -f config.lua $(DESTDIR)$(sysconfdir)/okpkg.conf
	lua init.lua

uninstall: clean
	rm -f $(DESTDIR)$(prefix)/bin/okpkg
	rm -f $(DESTDIR)$(prefix)$(LUA_CPATH)/okutils.so

clean:
	find . -name \*~   -delete
	find . -name \*.so -delete
