#include <sys/stat.h>
#include <sys/types.h>
#include <dirent.h>
#include <stdio.h>
#include "okutils.h"

/* return 0 if "." or ".." */
int
dotdot(char *s)
{
    int i;
    for (i = 0; i < 2 && *(s + i) && *(s + i) == '.'; ++i);
    return *(s + i) || i == 0;
}

void
remove_all(const char *path)
{
    char buf[PATH_MAX];
    DIR *db;
    struct dirent *de;
    struct stat sb;
    if ((db = opendir(path)) == NULL) return;
    while (de = readdir(db)) {
        if (dotdot(de->d_name)) {
            snprintf(buf, PATH_MAX, "%s/%s", path, de->d_name);
            if (lstat(buf, &sb) == 0) {
                if ((sb.st_mode & S_IFMT) == S_IFDIR) { 
                    remove_all(buf);
                } 
                else {
                    remove(buf);
                }
            }
        }
    }
    closedir(db);
    remove(path);
}

int
ok_remove_all(lua_State *L)
{
    const char *path = lua_tostring(L, 1);
    remove_all(path);
    return 0;
}

int
ok_dir(lua_State *L)
{
    const char *path;
    static DIR *db;
    struct dirent *de;
    if (path = lua_tostring(L, 1)) {
        db = opendir(path);
        lua_pushcfunction(L, ok_dir);
        return 1;
    }
    do {
        de = readdir(db);
    } while (db && de && !dotdot(de->d_name));
    if (de) {
        lua_pushstring(L, de->d_name);
        return 1;
    }
    return 0;
}

int
ok_mkdir(lua_State *L)
{
    const char *path = lua_tostring(L, 1);
    lua_pushinteger(L, mkdir(path, 0755));
    return 1;
}

int
ok_mtime(lua_State *L)
{
    const char *path = lua_tostring(L, 1);
    struct stat sb;
    if (lstat(path, &sb) == 0) {
        lua_pushinteger(L, sb.st_mtime);
        return 1;
    } 
    return 0;
}
