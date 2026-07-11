#include <unistd.h>
#include "okutils.h"

int
ok_symlink(lua_State *L)
{
    const char *target = luaL_checkstring(L, 1);
    const char *linkpath = luaL_checkstring(L, 2);
    lua_pushinteger(L, symlink(target, linkpath));
    return 1;
}

int
ok_link(lua_State *L)
{
    const char *oldpath = luaL_checkstring(L, 1);
    const char *newpath = luaL_checkstring(L, 2);
    lua_pushinteger(L, link(oldpath, newpath));
    return 1;
}
