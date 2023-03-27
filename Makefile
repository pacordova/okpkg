PREFIX=/usr

install:
	mkdir index packages sources 2>/dev/null || true
	install -D main.rc ${PREFIX}/bin/firepkg
