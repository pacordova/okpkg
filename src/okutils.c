#include <lauxlib.h>

int ok_chdir(lua_State *L);
int ok_exists(lua_State *L);
int ok_pwd(lua_State *L);
int ok_setenv(lua_State *L);
int ok_unsetenv(lua_State *L);
int ok_basename(lua_State *L);
int ok_dirname(lua_State *L);
int ok_symlink(lua_State *L);
int ok_mkdir(lua_State *L);
int ok_chroot(lua_State *L);
int ok_sha3sum(lua_State *L);
int ok_remove_all(lua_State *L);
int ok_directory_iterator(lua_State *L);

static const struct luaL_Reg okutils[] = {
    {"chdir", ok_chdir},
    {"exists", ok_exists},
    {"mkdir", ok_mkdir},
    {"pwd", ok_pwd},
    {"symlink", ok_symlink},
    {"basename", ok_basename},
    {"dirname", ok_dirname},
    {"setenv", ok_setenv},
    {"unsetenv", ok_unsetenv},
    {"chroot", ok_chroot},
    {"sha3sum", ok_sha3sum},
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
