#include <filesystem>
#include "okutils.h"

namespace fs = std::filesystem;

int
ok_directory_iterator(lua_State *L)
{
    const fs::path p = luaL_checkstring(L, 1);
    static fs::directory_iterator it;

    if (it == fs::end(it)) {
        it = fs::directory_iterator(p);
    }

    lua_pushcfunction(L, [](lua_State *L) {
        if (it == fs::end(it)) {
            return 0;
        }
        else {
            lua_pushstring(L, it->path().c_str());
            ++it;
            return 1;
        }
    });

    return 1;
}

int
ok_unlink(lua_State *L)
{
    const fs::path p = luaL_checkstring(L, 1);
    lua_pushinteger(L, fs::remove_all(p));
    return 1;
}

int
ok_mkdir(lua_State *L)
{
    const fs::path p = luaL_checkstring(L, 1);
    lua_pushinteger(L, fs::create_directory(p));
    return 1;
}
