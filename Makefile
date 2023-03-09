PREFIX=/usr

install: linux.so
	mkdir uninstall packages sources 2>/dev/null || true
	install -D main.lua ${PREFIX}/bin/firepkg

linux.so: linux.c
	gcc -shared -fPIC -fcommon -c linux.c -llua
	gcc -shared -o linux.so linux.o

clean:
	rm linux.o linux.so ${PREFIX}/bin/firepkg
