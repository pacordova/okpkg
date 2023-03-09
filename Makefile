PREFIX=/usr

install: linux.so
	mkdir uninstall packages sources 2>/dev/null || true
	install -D main.lua ${PREFIX}/bin/firepkg

linux.so: linux.c
	gcc -shared -o linux.so -fPIC -fcommon -llua linux.c

clean:
	rm linux.so ${PREFIX}/bin/firepkg
