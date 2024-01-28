PREFIX = /usr
LIBDIR = /usr/lib64

#LIBS += -llua5.4  -I/usr/include/lua5.4
LIBS += -I/usr/include/lua5.4
#LIBS +=-I/usr/include/luajit-2.0
CFLAGS += -Os -fstack-protector-strong -fstack-clash-protection \
		  -fcommon -fPIC -shared -pipe

all: utils.so

utils.so: utils.c
	cc ${LIBS} ${CFLAGS} -o $@ $^

${PREFIX}/bin/okpkg: utils.so
	>$@  printf '#!/usr/bin/env lua\n'
	>>$@ printf 'dofile "/usr/okpkg/okpkg.lua"\n'
	>>$@ printf 'if #arg == 1 then _G[arg[1]]() end\n'
	>>$@ printf 'while #arg > 1 do\n' 
	>>$@ printf '    _G[arg[1]](arg[2])\n'
	>>$@ printf '    table.remove(arg, 2)\n'
	>>$@ printf 'end\n'

install: ${PREFIX}/bin/okpkg
	mkdir index packages sources 2>/dev/null || true
	cp utils.so ${LIBDIR}/lua/5.4/utils.so
	chmod +x ${PREFIX}/bin/okpkg

uninstall: utils.so ${PREFIX}/bin/okpkg ${LIBDIR}/lua/5.4/utils.so
	rm $^
