#include <stdio.h>
#include "okutils.h"

void
sumfile(FILE *fp, unsigned char *out, size_t outlen)
{
    char buf[16384];
    struct blake3 ctx;
    size_t len;

    blake3_init(&ctx);
    do {
        len = fread(buf, 1, sizeof(buf), fp);
        if (len > 0)
            blake3_update(&ctx, buf, len);
    } while (len == sizeof(buf));
    blake3_out(&ctx, out, outlen);
}

int
ok_b3sum(lua_State *L)
{
    const char *name = luaL_checkstring(L, 1);
    FILE *fp = fopen(name, "rb");
    if (!fp) {
        fprintf(stderr, "error: b3sum: fopen\n");
        lua_pushinteger(L, -1);
        return 1;
    }

    size_t outlen = 32; // 256 bit
    unsigned char out[outlen];
    sumfile(fp, out, outlen);
    fclose(fp);

    char hex[2*outlen];
    for (int i = 0; i < 256/8; ++i)
        sprintf(hex + 2 * i, "%.2x", out[i]);

    printf("%s %s\n", hex, name);
    lua_pushstring(L, hex);
    return 1;
}
