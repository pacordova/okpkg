#include <lauxlib.h>
#include <libgen.h>

int
ok_basename(lua_State *L)
{
    const char *arg = luaL_checkstring(L, 1);
    lua_pushstring(L, basename((char*) arg));
    return 1;
}
