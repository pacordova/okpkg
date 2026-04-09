#include <filesystem>
namespace fs = std::filesystem;

extern "C" {
#include <lauxlib.h>
int ok_remove_all(lua_State *L);
}

int
ok_remove_all(lua_State *L)
{
	const fs::path p = luaL_checkstring(L, 1);
	lua_pushinteger(L, fs::remove_all(p));
	return 1;
}
