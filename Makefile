prefix = /usr

LUA_INCLUDE = $(shell dirname `find /usr/include -name 'lua.h'`)
LUA_CPATH = $(shell dirname `lua -e 'print(package.cpath)' | cut -d ';' -f1`)

CC = gcc
CFLAGS += -O2 -fPIC -shared
LDFLAGS = -lcrypto

all: okutils.so

okutils.so: okutils.c
	$(CC) -I$(LUA_INCLUDE) $(CFLAGS) -o $@ $^ $(LDFLAGS)
	strip $@

okpkg: okutils.so
	chmod +x $@

install: okutils.so
	mkdir -p index packages sources download
	mkdir -p $(DESTDIR)$(LUA_CPATH) 
	cp -p okutils.so $(DESTDIR)$(LUA_CPATH)
	mkdir -p $(DESTDIR)$(prefix)/bin
	ln -sf /usr/okpkg/okpkg.lua $(DESTDIR)$(prefix)/bin/okpkg

uninstall: clean
	rm -f $(DESTDIR)$(prefix)/bin/okpkg
	rm -f $(DESTDIR)$(prefix)$(LUA_CPATH)/okutils.so

clean: 
	rm -f okutils.so 

