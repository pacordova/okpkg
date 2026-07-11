#include "okutils.h"

static const struct luaL_Reg okutils[] = {
    {"chdir", ok_chdir},
    {"exists", ok_exists},
    {"mkdir", ok_mkdir},
    {"pwd", ok_pwd},
    {"symlink", ok_symlink},
    {"link", ok_link},
    {"basename", ok_basename},
    {"dirname", ok_dirname},
    {"setenv", ok_setenv},
    {"unsetenv", ok_unsetenv},
    {"chroot", ok_chroot},
    {"b3sum", ok_b3sum},
    {"remove_all", ok_remove_all},
    {"directory_iterator", ok_directory_iterator},
    {NULL, NULL},
};

int
luaopen_okutils(lua_State *L)
{
    luaL_newlib(L, okutils);
    return 1;
}
