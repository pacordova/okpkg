#include <sys/mount.h>
#include <unistd.h>
#include "okutils.h"

#define TOPFLAGS 4096   /* bind */
#define DEVFLAGS 544771 /* bind,rslave,ro,nosuid */
#define SYSFLAGS 544783 /* bind,rslave,ro,nosuid,noexec,nodev */

int
ok_chroot(lua_State *L)
{
    const char *path = lua_tostring(L, 1);
    char *const cmd[] = {"/bin/sh", "-i", NULL};
    if (chdir(path)) return 0;
    mount(path, path, NULL, TOPFLAGS, NULL);
    mount("/proc", "proc", "proc", SYSFLAGS, "hidepid=1");
    mount("/sys", "sys", "sysfs", SYSFLAGS, NULL);
    mount("/dev", "dev", "devtmpfs", DEVFLAGS, NULL);
    if (chroot(".") || chdir("/") || execvp(cmd[0], cmd)) return 0;
}
