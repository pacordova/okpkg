#include <lauxlib.h>
#include <stdlib.h>

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
