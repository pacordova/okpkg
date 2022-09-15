PREFIX=/usr

install:
	mkdir uninstall packages sources || true
	install -D main.rc ${PREFIX}/bin/firepkg
