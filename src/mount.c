#include <sys/mount.h>
#include "okutils.h"

#define UNMOUNT umount2

int
ok_mount(lua_State *L)
{
    const char *device = lua_tostring(L, 1);
    const char *path = lua_tostring(L, 2);
    const char *type = lua_tostring(L, 3);
    int flags = (int) lua_tointeger(L, 4);
    void *data = (void*) lua_tostring(L, 5);
    lua_pushinteger(L, mount(device, path, type, flags, data));
    return 1;
}

int
ok_unmount(lua_State *L)
{
    const char *path = lua_tostring(L, 1);
    int flags = (int) lua_tointeger(L, 2);
    lua_pushinteger(L, UNMOUNT(path, flags));
    return 1;
}
