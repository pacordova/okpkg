#include <lauxlib.h>
#include <unistd.h>

int
ok_exists(lua_State *L)
{
	const char *path = luaL_checkstring(L, 1);
	lua_pushboolean(L, !access(path, F_OK));
	return 1;
}
