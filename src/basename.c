#include <lauxlib.h>
#include <libgen.h>

int
ok_basename(lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);
    lua_pushstring(L, basename((char *)path));
    return 1;
}

int
ok_dirname(lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);
    lua_pushstring(L, dirname((char *)path));
    return 1;
}
