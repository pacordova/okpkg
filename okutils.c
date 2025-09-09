#include <stdio.h>
#include <string.h>
#include <linux/limits.h>
#include <unistd.h>
#include <stdlib.h>
#include <libgen.h>
#include <sys/stat.h>
#include <openssl/evp.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#define DIRMODE 0777
#define BUFSIZE 4096
#define MDSIZE 256/8

int
ok_chdir(lua_State *L)
{
	const char *path = luaL_checkstring(L, 1);
	lua_pushinteger(L, chdir(path));

	return 1;
}

int
ok_pwd(lua_State *L)
{
	char buf[PATH_MAX];
	lua_pushstring(L, (const char*) getcwd(buf, PATH_MAX));

	return 1;
}

int
ok_setenv(lua_State *L)
{
	const char *name = luaL_checkstring(L, 1);
	const char *value = luaL_checkstring(L, 2);
	lua_pushinteger(L, setenv(name, value, 1));

	return 1;
}

int
ok_unsetenv(lua_State *L)
{
	const char *name = luaL_checkstring(L, 1);
	lua_pushinteger(L, unsetenv(name));

	return 1;
}


int
ok_basename(lua_State *L)
{
	const char *arg = luaL_checkstring(L, 1);
	char path[PATH_MAX];
	strcpy(path, arg);
	lua_pushstring(L, basename(path));

	return 1;
}

int
ok_dirname(lua_State *L)
{
	const char *arg = luaL_checkstring(L, 1);
	char path[PATH_MAX];
	strcpy(path, arg);
	lua_pushstring(L, dirname(path));

	return 1;
}

int
ok_symlink(lua_State *L)
{
	const char *path1 = luaL_checkstring(L, 1);
	const char *path2 = luaL_checkstring(L, 2);
	lua_pushinteger(L, symlink(path1, path2));

	return 1;
}

int
ok_mkdir(lua_State *L)
{
	const char *pathname = luaL_checkstring(L, 1);
	lua_pushinteger(L, mkdir(pathname, DIRMODE));

	return 1;
}

int
ok_chroot(lua_State *L)
{
	const char *path = luaL_checkstring(L, 1);
	char *const cmd[] = {"/bin/sh", "-i", NULL};
	const char *term = (const char*) getenv("TERM");


	if (chdir(path)) {
		fprintf(stderr, "error: chroot: chdir: %s\n", path);
		lua_pushinteger(L, -1);
		return 1;
	}
	else {
		mkdir("proc", DIRMODE);
		mkdir("sys", DIRMODE);
		mkdir("dev", DIRMODE);
	}

	const char *mountcmd =
		"mountpoint -q proc || mount -t proc  -o ro /proc proc/;"
		"mountpoint -q sys  || mount -t sysfs -o ro /sys sys/;"
		"mountpoint -q dev  || mount --rbind  -o ro /dev dev/;"
		"mount --make-rslave dev/";

	if (system(mountcmd)) {
		fprintf(stderr, "error: chroot: mount\n");
		lua_pushinteger(L, -1);
		return 1;
	}
	else {
		/* env */
		clearenv();
		setenv("PATH", "/usr/bin:/usr/sbin", 1);
		setenv("HOME", "/root", 1);
		setenv("USER", "root", 1);
		setenv("LC_ALL", "C", 1);
		setenv("SHELL", "/bin/sh", 1);
		setenv("PS1", "(chroot) \\W \\$ ", 1);
		setenv("TERM", term, 1);
	}

	if (chroot(path) || chdir("/") || execvp(cmd[0], cmd)) {
		fprintf(stderr, "error: chroot: execvp\n");
		lua_pushinteger(L, -1);
		return 1;
	}
	else {
		lua_pushinteger(L, 0);
		return 1;
	}
}

int
ok_sha3sum(lua_State *L)
{
	const char *path = luaL_checkstring(L, 1);

	FILE *fp = fopen(path, "rb");
	if (!fp) {
		fprintf(stderr, "error: sha3sum: fopen: %s\n", path);
		lua_pushinteger(L, -1);
		return 1;
	}

	static char output[MDSIZE*2];
	unsigned char buf[BUFSIZE], md[MDSIZE];
	EVP_MD_CTX *mdctx = EVP_MD_CTX_new();
	EVP_DigestInit_ex(mdctx, EVP_sha3_256(), NULL);

	size_t cnt;
	do {
		cnt = fread(buf, 1, sizeof(buf), fp);
		EVP_DigestUpdate(mdctx, buf, cnt);
	} while(cnt > 0);

	EVP_DigestFinal_ex(mdctx, md, NULL);
	EVP_MD_CTX_free(mdctx);
	fclose(fp);

	for(int i = 0; i<MDSIZE; ++i)
		sprintf(output+2*i, "%.2x", md[i]);

	printf("%s %s\n", output, path);

	lua_pushstring(L, (const char*) output);
	return 1;
}

static const struct luaL_Reg okutils[] = {
	{"chdir", ok_chdir},
	{"mkdir", ok_mkdir},
	{"pwd", ok_pwd},
	{"symlink", ok_symlink},
	{"basename", ok_basename},
	{"dirname", ok_dirname},
	{"setenv", ok_setenv},
	{"unsetenv", ok_unsetenv},
	{"chroot", ok_chroot},
	{"sha3sum", ok_sha3sum},
	{NULL, NULL}
};

int
luaopen_okutils(lua_State *L)
{
	luaL_newlib(L, okutils);
	return 1;
}
