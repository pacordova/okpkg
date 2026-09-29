#include <unistd.h>
#include <sys/wait.h>
#include "okutils.h"

int
ok_exec(lua_State *L)
{
    int i, pid, wstatus;
    int argc = lua_gettop(L);
    char *argv[argc+1];
    for (i = 0; i < argc; ++i)
        argv[i] = (char *) lua_tostring(L, i+1);
    argv[argc+1] = (char *) NULL;
    switch(pid = fork()) {
    case -1:
        return -1;
    case 0:
        execvp(argv[0], argv);
        _exit(0);
    default:
        wait(&wstatus);
        if (WIFEXITED(wstatus)) {
            lua_pushinteger(L, WEXITSTATUS(wstatus));
            return 1;
        }
    }
    return 0;
}
