#include <lauxlib.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>

int
ok_chroot(lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);
    char *const cmd[] = {"/bin/sh", "-i", NULL};
    const char *term = (const char *)getenv("TERM");

    if (chdir(path)) {
        fprintf(stderr, "error: chroot: chdir: %s\n", path);
        lua_pushinteger(L, -1);
        return 1;
    }
    else {
        mkdir("proc",     0555);
        mkdir("sys",      0555);
        mkdir("dev",      0755);
        mkdir("run",      0775);
        mkdir("run/lock", 0755);
    }

    const char *mountcmd =
        "mountpoint -q proc || mount -t proc  -o ro /proc proc/;"
        "mountpoint -q sys  || mount -t sysfs -o ro /sys sys/;"
        "mountpoint -q dev  || mount --rbind  -o ro /dev dev/;"
        "mount --make-rslave dev/";

    if (system(mountcmd)) {
        fprintf(stderr, "error: chroot: mount\n");
        lua_pushinteger(L, -1);
        return 1;
    }
    else {
        /* env */
        clearenv();
        setenv("PATH", "/usr/bin:/usr/sbin", 1);
        setenv("HOME", "/root", 1);
        setenv("USER", "root", 1);
        setenv("LC_ALL", "C", 1);
        setenv("SHELL", "/bin/sh", 1);
        setenv("PS1", "(chroot) \\W \\$ ", 1);
        setenv("TERM", term, 1);
    }

    if (chroot(path) || chdir("/") || execvp(cmd[0], cmd)) {
        fprintf(stderr, "error: chroot: execvp\n");
        lua_pushinteger(L, -1);
        return 1;
    }
    else {
        lua_pushinteger(L, 0);
        return 1;
    }
}
