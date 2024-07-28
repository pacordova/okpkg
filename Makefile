prefix = /usr

LUA_INCLUDE = $(shell dirname `find /usr/include -name lua.h | head -1`)
LUA_CPATH = $(shell dirname `lua -e 'print(package.cpath)' | cut -d ';' -f1`)

CC = gcc
CFLAGS += -O2 -fPIC -shared
LDFLAGS = -lcrypto

all: okutils.so

okutils.so: okutils.c
	$(CC) -I$(LUA_INCLUDE) $(CFLAGS) -o $@ $^ $(LDFLAGS)
	strip --strip-unneeded $@

install: okutils.so
	mkdir -p index packages sources download
	install -d $(DESTDIR)$(prefix)/bin $(DESTDIR)$(LUA_CPATH)
	install okutils.so $(DESTDIR)$(LUA_CPATH)/
	ln -sf /usr/okpkg/okpkg.lua $(DESTDIR)$(prefix)/bin/okpkg

uninstall: clean
	rm -f $(DESTDIR)$(prefix)/bin/okpkg
	rm -f $(DESTDIR)$(prefix)$(LUA_CPATH)/okutils.so

clean: 
	find . -name \*~ -delete
	rm -f okutils.so 
