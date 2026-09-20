#include <lua.h>
#include <stdint.h>

#ifndef PATH_MAX
#define PATH_MAX 4096
#endif

#ifndef BLAKE3_H
#define BLAKE3_H 1

struct blake3 {
    unsigned char input[64];      /* current input bytes */
    unsigned bytes;               /* bytes in current input block */
    unsigned block;               /* block index in chunk */
    uint64_t chunk;               /* chunk index */
    uint32_t *cv, cv_buf[54 * 8]; /* chain value stack */
};

void blake3_init(struct blake3 *);
void blake3_update(struct blake3 *, const void *, size_t);
void blake3_out(struct blake3 *, unsigned char *restrict, size_t);

#endif

int luaopen_okutils(lua_State *L);
int ok_b3sum(lua_State *L);
int ok_chroot(lua_State *L);
int ok_basename(lua_State *L);
int ok_dirname(lua_State *L);
int ok_chdir(lua_State *L);
int ok_exists(lua_State *L);
int ok_getcwd(lua_State *L);
int ok_symlink(lua_State *L);
int ok_remove_all(lua_State *L);
int ok_dir(lua_State *L);
int ok_mkdir(lua_State *L);
int ok_setenv(lua_State *L);
int ok_unsetenv(lua_State *L);
