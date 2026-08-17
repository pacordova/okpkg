#include <filesystem>
#include "okutils.h"

namespace fs = std::filesystem;

int
ok_directory_iterator(lua_State *L)
{
    const fs::path p = luaL_checkstring(L, 1);
    static fs::directory_iterator it;

    it = fs::directory_iterator(p);

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
ok_remove_all(lua_State *L)
{
    const fs::path p = luaL_checkstring(L, 1);
    lua_pushinteger(L, fs::remove_all(p));
    return 1;
}

int
ok_create_directory(lua_State *L)
{
    const fs::path p = luaL_checkstring(L, 1);
    lua_pushinteger(L, fs::create_directory(p));
    return 1;
}

int
ok_exists(lua_State *L)
{
    const fs::path p = luaL_checkstring(L, 1);
    lua_pushboolean(L, fs::exists(p));
    return 1;
}

int
ok_create_symlink(lua_State *L)
{
    const fs::path target = luaL_checkstring(L, 1);
    const fs::path link   = luaL_checkstring(L, 2);
    fs::create_symlink(target, link);
    return 0;
}

int
ok_current_path(lua_State *L)
{
    if (lua_gettop(L)) {
        const fs::path p = luaL_checkstring(L, 1);
        fs::current_path(p);
        return 0;
    }
    else {
        const fs::path p = fs::current_path();
        lua_pushstring(L, p.c_str());
        return 1;
    }
}
