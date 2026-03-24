#include <lauxlib.h>

int ok_chdir(lua_State *L);
int ok_pwd(lua_State *L);
int ok_setenv(lua_State *L); 
int ok_unsetenv(lua_State *L);
int ok_basename(lua_State *L);
int ok_dirname(lua_State *L);
int ok_symlink(lua_State *L);
int ok_mkdir(lua_State *L);
int ok_chroot(lua_State *L);
int ok_sha3sum(lua_State *L);

static const struct luaL_Reg okutils [] = {
	{"chdir", ok_chdir},
	{"mkdir", ok_mkdir},
	{"pwd", ok_pwd},
	{"symlink", ok_symlink},
	{"basename", ok_basename},
	{"dirname", ok_dirname},
	{"setenv", ok_setenv},
	{"unsetenv", ok_unsetenv},
	{"chroot", ok_chroot},
	{"sha3sum", ok_sha3sum},
	{NULL, NULL}
};

int
luaopen_okutils(lua_State *L)
{
	luaL_newlib(L, okutils);
	return 1;
}
