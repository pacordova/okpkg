#include <lauxlib.h>
#include <libgen.h>

int
ok_dirname(lua_State *L)
{
    const char *arg = luaL_checkstring(L, 1);
    lua_pushstring(L, dirname((char*) arg));
    return 1;
}
