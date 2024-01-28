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
utils_chdir(lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);
    lua_pushinteger(L, chdir(path));

    return 1;
}

int
utils_setenv(lua_State *L)
{
    const char *name = luaL_checkstring(L, 1);
    const char *value = luaL_checkstring(L, 2);
    lua_pushinteger(L, setenv(name, value, 1));

    return 1;
}

int
utils_unsetenv(lua_State *L)
{
    const char *name = luaL_checkstring(L, 1);
    lua_pushinteger(L, unsetenv(name));

    return 1;
}


int
utils_basename(lua_State *L)
{
    const char *arg = luaL_checkstring(L, 1);
    char path[PATH_MAX];
    strcpy(path, arg);
    lua_pushstring(L, basename(path));

    return 1;
}

int
utils_symlink(lua_State *L)
{
    const char *path1 = luaL_checkstring(L, 1);
    const char *path2 = luaL_checkstring(L, 2);
    lua_pushinteger(L, symlink(path1, path2));

    return 1;
}

int
utils_mkdir(lua_State *L)
{
    const char *pathname = luaL_checkstring(L, 1);
    lua_pushinteger(L, mkdir(pathname, DIRMODE));

    return 1;
}

int
luaopen_utils(lua_State *L) 
{    
    /* chdir */
    lua_pushcfunction(L, utils_chdir);
    lua_setglobal(L, "chdir");

    /* setenv */
    lua_pushcfunction(L, utils_setenv);
    lua_setglobal(L, "setenv");

    /* unsetenv */
    lua_pushcfunction(L, utils_unsetenv);
    lua_setglobal(L, "unsetenv");

    /* basename */
    lua_pushcfunction(L, utils_basename);
    lua_setglobal(L, "basename");

    /* symlink */
    lua_pushcfunction(L, utils_symlink);
    lua_setglobal(L, "symlink");

    /* mkdir */
    lua_pushcfunction(L, utils_mkdir);
    lua_setglobal(L, "mkdir");

    return 0;
}
