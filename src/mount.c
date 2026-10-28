#include <sys/mount.h>
#include "okutils.h"

int
ok_mount(lua_State *L)
{
    const char *device = lua_tostring(L, 1);
    const char *path   = lua_tostring(L, 2);
    const char *type   = lua_tostring(L, 3);
    const int flags    = lua_tointeger(L, 4);
    const char *data   = lua_tostring(L, 5);
    lua_pushinteger(L, mount(device, path, type, flags, data));
    return 1;
}
