PREFIX=/usr

install:
	>[2=] mkdir uninstall packages sources || true
	install -D main.rc ${PREFIX}/bin/firepkg
