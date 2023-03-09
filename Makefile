all:
	gcc -shared -fPIC -fcommon -c linux.c -llua
	gcc -shared -o linux.so linux.o
