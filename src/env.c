#include <stdlib.h>
#include "okutils.h"

int
ok_setenv(lua_State *L)
{
    const char *k = lua_tostring(L, 1);
    const char *v = lua_tostring(L, 2);
    lua_pushboolean(L, setenv(k, v, 1) == 0);
    return 1;
}

int
ok_unsetenv(lua_State *L)
{
    const char *name = lua_tostring(L, 1);
    lua_pushboolean(L, unsetenv(name) == 0);
    return 1;
}
