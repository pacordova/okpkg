#include <linux/limits.h>
#include <lua.h>
#include <unistd.h>

int
ok_pwd(lua_State *L)
{
  char buf[PATH_MAX];
  lua_pushstring(L, (const char *)getcwd(buf, PATH_MAX));
  return 1;
}
