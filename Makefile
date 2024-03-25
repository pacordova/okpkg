PREFIX = /usr

LIBS += -I/usr/include/lua5.4
#LIBS += -llua5.4  -I/usr/include/lua5.4
#LIBS +=-I/usr/include/luajit-2.0

CFLAGS += -O2 -fstack-protector -fstack-clash-protection \
		  -fcommon -fPIC -shared -pipe

all: okutils.so

okutils.so: okutils.c
	cc ${LIBS} ${CFLAGS} -o $@ $^
	strip --strip-unneeded $@

${PREFIX}/bin/okpkg: okutils.so
	>$@  printf '#!/usr/bin/env lua\n'
	>>$@ printf 'dofile "/usr/okpkg/okpkg.lua"\n'
	>>$@ printf 'if #arg == 1 then _G[arg[1]]() end\n'
	>>$@ printf 'while #arg > 1 do\n' 
	>>$@ printf '    _G[arg[1]](arg[2])\n'
	>>$@ printf '    table.remove(arg, 2)\n'
	>>$@ printf 'end\n'
	chmod +x $@

install: ${PREFIX}/bin/okpkg okutils.so
	mkdir -p index packages sources download || true

uninstall: ${PREFIX}/bin/okpkg okutils.so
	rm $^
	make clean

clean: okutils.so
	rm $^
