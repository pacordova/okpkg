#include <lauxlib.h>
#include <sys/stat.h>

int
ok_mkdir(lua_State *L)
{
    const char *pathname = luaL_checkstring(L, 1);
    lua_pushinteger(L, mkdir(pathname, 0777));
    return 1;
}
