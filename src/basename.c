#include "okutils.h"

int
ok_basename(lua_State *L)
{
    const char *path = lua_tostring(L, 1);
    const char *i;
    for (i = path; *i; ++i)
        if (*i == '/') path = i + 1;
    lua_pushstring(L, path);
    return 1;
}

int
ok_dirname(lua_State *L)
{
    const char *path = lua_tostring(L, 1);
    const char *i;
    char *j;
    for (i = path; *i; ++i)
        if (*i == '/') j = (char *)i;
    *j = '\0';
    lua_pushstring(L, path);
    return 1;
}
