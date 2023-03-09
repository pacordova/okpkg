#include <stdlib.h>
#include <unistd.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

int 
lua_chdir(lua_State *L)
{
    const char* path = luaL_checkstring(L, 1);
    chdir(path);
    return 0;
}

int 
lua_setenv(lua_State *L)
{
    const char* name = luaL_checkstring(L, 1);
    const char* value = luaL_checkstring(L, 2);
    int overwrite = (int) luaL_checknumber(L, 3);
    setenv(name, value, overwrite);
    return 0;
}

static const struct luaL_Reg lua_linux [] = {
    {"chdir", lua_chdir},
    {"setenv", lua_setenv},
    {NULL, NULL} 
};

int 
luaopen_linux (lua_State *L) 
{
    luaL_newlib(L, lua_linux);
    return 1;
}
