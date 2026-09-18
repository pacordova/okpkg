#include <unistd.h>
#include "okutils.h"

int
ok_chdir(lua_State *L)
{
    const char *path = lua_tostring(L, 1);
    lua_pushinteger(L, chdir(path));
    return 1;
}

int
ok_exists(lua_State *L)
{
    const char *path = lua_tostring(L, 1);
    lua_pushboolean(L, access(path, F_OK) == 0);
    return 1;
}

int
ok_getcwd(lua_State *L)
{
    char buf[PATH_MAX];
    lua_pushstring(L, getcwd(buf, PATH_MAX));
    return 1;
};

int
ok_symlink(lua_State *L)
{
    const char *target = lua_tostring(L, 1);
    const char *link = lua_tostring(L, 2);
    lua_pushinteger(L, symlink(target, link));
    return 1;
}
