#include <filesystem>
namespace fs = std::filesystem;

extern "C" {
#include <lauxlib.h>
int ok_directory_iterator(lua_State *L);
}

int
ok_directory_iterator(lua_State *L)
{
    const fs::path p = luaL_checkstring(L, 1);
    static fs::directory_iterator i;
    if (i == fs::end(i))
        i = fs::directory_iterator(p);
    lua_pushcfunction(L, [](lua_State *L) {
        if (i == fs::end(i))
            return 0;
        lua_pushstring(L, i->path().c_str());
        ++i;
        return 1;
    });
    return 1;
}
