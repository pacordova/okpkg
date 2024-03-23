#include <stdio.h>
#include <string.h>
#include <linux/limits.h>
#include <unistd.h>
#include <stdlib.h>
#include <libgen.h>
#include <sys/stat.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#define DIRMODE 0777

int
okutils_chroot(lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);
    char *const cmd[] = {"/bin/sh", "-i", NULL}; 
    const char *term = (const char*) getenv("TERM");

    if (chdir(path)) {
        fprintf(stderr, "error: chdir(\"%s\")\n", path);
        lua_pushinteger(L, -1);
        return 1;
    }

    /* we don't care if these error */
    mkdir("proc", DIRMODE);
    system("mount -t proc -o ro /proc proc/ 2>/dev/null");
    mkdir("sys", DIRMODE);
    system("mount -t sysfs -o ro /sys sys/ 2>/dev/null");
    mkdir("dev", DIRMODE);
    system("mount --rbind -o ro /dev dev/ 2>/dev/null");
    system("mount --make-rslave dev/ 2>/dev/null");

    /* env */
    clearenv();
    setenv("PATH", "/usr/bin", 1);
    setenv("HOSTNAME", "myhost", 1);
    setenv("HOME", "/root", 1);
    setenv("USER", "root", 1);
    setenv("LC_ALL", "C", 1);
    setenv("SHELL", "/bin/sh", 1);
    setenv("PS1", "(chroot)# ", 1);
    setenv("TERM", term, 1);

    if (chroot(path) || chdir("/") || execvp(cmd[0], cmd)) {
        fprintf(stderr, "error: chroot\n");
        lua_pushinteger(L, -1);
    } else {
        lua_pushinteger(L, 0);
    }

    return 1;
}

int 
okutils_chdir(lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);
    lua_pushinteger(L, chdir(path));

    return 1;
}

int
okutils_setenv(lua_State *L)
{
    const char *name = luaL_checkstring(L, 1);
    const char *value = luaL_checkstring(L, 2);
    lua_pushinteger(L, setenv(name, value, 1));

    return 1;
}

int
okutils_unsetenv(lua_State *L)
{
    const char *name = luaL_checkstring(L, 1);
    lua_pushinteger(L, unsetenv(name));

    return 1;
}


int
okutils_basename(lua_State *L)
{
    const char *arg = luaL_checkstring(L, 1);
    char path[PATH_MAX];
    strcpy(path, arg);
    lua_pushstring(L, basename(path));

    return 1;
}

int
okutils_symlink(lua_State *L)
{
    const char *path1 = luaL_checkstring(L, 1);
    const char *path2 = luaL_checkstring(L, 2);
    lua_pushinteger(L, symlink(path1, path2));

    return 1;
}

int
okutils_mkdir(lua_State *L)
{
    const char *pathname = luaL_checkstring(L, 1);
    lua_pushinteger(L, mkdir(pathname, DIRMODE));

    return 1;
}

int
luaopen_okutils(lua_State *L) 
{    
    /* chroot */
    lua_pushcfunction(L, okutils_chroot);
    lua_setglobal(L, "chroot");

    /* chdir */
    lua_pushcfunction(L, okutils_chdir);
    lua_setglobal(L, "chdir");

    /* setenv */
    lua_pushcfunction(L, okutils_setenv);
    lua_setglobal(L, "setenv");

    /* unsetenv */
    lua_pushcfunction(L, okutils_unsetenv);
    lua_setglobal(L, "unsetenv");

    /* basename */
    lua_pushcfunction(L, okutils_basename);
    lua_setglobal(L, "basename");

    /* symlink */
    lua_pushcfunction(L, okutils_symlink);
    lua_setglobal(L, "symlink");

    /* mkdir */
    lua_pushcfunction(L, okutils_mkdir);
    lua_setglobal(L, "mkdir");

    return 0;
}
