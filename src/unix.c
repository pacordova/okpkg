#include <unistd.h>
#include "okutils.h"

int
ok_chdir(lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);
    lua_pushinteger(L, chdir(path));
    return 1;
}

int
ok_exists(lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);
    lua_pushboolean(L, !access(path, F_OK));
    return 1;
}

int
ok_pwd(lua_State *L)
{
    char buf[4096];
    lua_pushstring(L, (const char *)getcwd(buf, 4096));
    return 1;
}

int
ok_symlink(lua_State *L)
{
    const char *target = luaL_checkstring(L, 1);
    const char *linkpath = luaL_checkstring(L, 2);
    lua_pushinteger(L, symlink(target, linkpath));
    return 1;
}
