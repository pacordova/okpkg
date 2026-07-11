#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/mount.h>
#include <unistd.h>
#include "okutils.h"

#define DEFAULT (MS_BIND| MS_REC | MS_SLAVE | MS_RDONLY | MS_NOSUID)

int
pivot_root(const char *new_root, const char *put_old) 
{
    return syscall(SYS_pivot_root, new_root, put_old);
}

int
ok_chroot(lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);
    char *const cmd[] = {"/bin/sh", "-i", NULL};
//    const char *term = (const char *)getenv("TERM");

    if (chdir(path)) {
        lua_pushinteger(L, -1);
        return 1;
    }

    if (access("./proc", F_OK)) mkdir("./proc", 0555);
    mount("/proc", "proc", "proc", MS_NOEXEC|MS_NODEV|DEFAULT, "hidepid=1");

    if (access("./sys", F_OK)) mkdir("./sys", 0555);
    mount("/sys", "sys", "sysfs", MS_NOEXEC|MS_NODEV|DEFAULT, NULL);

    if (access("./dev", F_OK)) mkdir("./dev", 0755);
    mount("/dev", "dev", "devtmpfs", DEFAULT, NULL);

    if (chroot(".") || chdir("/") || execvp(cmd[0], cmd)) {
        lua_pushinteger(L, -1);
        return 1;
    }
}
