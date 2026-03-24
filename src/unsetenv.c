#include <lauxlib.h>
#include <stdlib.h>

int
ok_unsetenv(lua_State *L)
{
	const char *name = luaL_checkstring(L, 1);
	lua_pushinteger(L, unsetenv(name));
	return 1;
}
