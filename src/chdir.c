#include <lauxlib.h>
#include <unistd.h>

int
ok_chdir(lua_State *L)
{
  const char *path = luaL_checkstring(L, 1);
  lua_pushinteger(L, chdir(path));
  return 1;
}
