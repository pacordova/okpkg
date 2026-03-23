prefix     = /usr
sysconfdir = /etc
bindir     = $(prefix)/bin

CC        = /usr/bin/gcc -std=gnu99
CFLAGS    = -O2 -fpic -shared -pipe `pkgconf --cflags lua`
LDFLAGS   = `pkgconf --libs libcrypto`
LUA_CPATH = `lua -e "print(package.cpath:match('(.-)/%?.so;'))"`


okutils.so: okutils.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)
	strip --strip-unneeded $@

install: okutils.so
	mkdir -p $(DESTDIR)$(bindir) $(DESTDIR)$(LUA_CPATH)
	mv -f okutils.so $(DESTDIR)$(LUA_CPATH)
	cp -f main.lua   $(DESTDIR)$(bindir)/okpkg
	cp -f config.lua $(DESTDIR)$(sysconfdir)/okpkg.conf
	lua init.lua

uninstall: clean
	rm -f $(DESTDIR)$(prefix)/bin/okpkg
	rm -f $(DESTDIR)$(prefix)$(LUA_CPATH)/okutils.so

clean:
	find . -name \*~   -delete
	find . -name \*.so -delete
