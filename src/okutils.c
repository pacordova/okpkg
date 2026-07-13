#include "okutils.h"

static const struct luaL_Reg okutils[] = {
    {"b3sum", ok_b3sum},
    {"chroot", ok_chroot},
    {"create_directory", ok_create_directory},
    {"create_symlink", ok_create_symlink},
    {"current_path", ok_current_path},
    {"directory_iterator", ok_directory_iterator},
    {"exists", ok_exists},
    {"remove_all", ok_remove_all},
    {"setenv", ok_setenv},
    {"unsetenv", ok_unsetenv},
    {NULL, NULL},
};

int
luaopen_okutils(lua_State *L)
{
    luaL_newlib(L, okutils);
    return 1;
}
