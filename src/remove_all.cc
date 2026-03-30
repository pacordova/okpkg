#include <filesystem>

extern "C" {

#include <lauxlib.h>

int
ok_remove_all(lua_State *L) 
{
    const std::filesystem::path p = luaL_checkstring(L, 1);
    lua_pushinteger(L, std::filesystem::remove_all(p));
    return 1;
}

}
