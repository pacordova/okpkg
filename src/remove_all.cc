#include <filesystem>
#include "okutils.h"

namespace fs = std::filesystem;

int
ok_remove_all(lua_State *L)
{
    const fs::path p = luaL_checkstring(L, 1);
    lua_pushinteger(L, fs::remove_all(p));
    return 1;
}
