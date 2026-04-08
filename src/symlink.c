#include <lauxlib.h>
#include <unistd.h>

int
ok_symlink(lua_State *L)
{
  const char *target = luaL_checkstring(L, 1);
  const char *linkpath = luaL_checkstring(L, 2);
  lua_pushinteger(L, symlink(target, linkpath));
  return 1;
}
