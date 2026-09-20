#include "okutils.h"
#include <lauxlib.h>

static const struct luaL_Reg okutils[] = {
    {"b3sum", ok_b3sum},
    {"chroot", ok_chroot},
    {"basename", ok_basename},
    {"dirname", ok_dirname},
    {"chdir", ok_chdir},
    {"exists", ok_exists},
    {"getcwd", ok_getcwd},
    {"symlink", ok_symlink},
    {"mkdir", ok_mkdir},
    {"remove_all", ok_remove_all},
    {"setenv", ok_setenv},
    {"unsetenv", ok_unsetenv},
    {NULL, NULL},
};

static const struct luaL_Reg globals[] = {
    {"dir", ok_dir},
    {NULL, NULL},
};

int
luaopen_okutils(lua_State *L)
{
    const luaL_Reg *p = globals;
    for (; p->name; ++p) {
        lua_pushcfunction(L, p->func);
        lua_setglobal(L, p->name);
    }
    luaL_newlib(L, okutils);
    return 1;
}
