#include <lauxlib.h>
#include <openssl/evp.h>

#define BUFSIZE 4096
#define MDSIZE 256 / 8

int
ok_sha3sum(lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);
    FILE *fp = fopen(path, "rb");
    if (!fp) {
        fprintf(stderr, "error: sha3sum: fopen: %s\n", path);
        lua_pushinteger(L, -1);
        return 1;
    }
    static char output[MDSIZE * 2];
    unsigned char buf[BUFSIZE], md[MDSIZE];
    EVP_MD_CTX *mdctx = EVP_MD_CTX_new();
    EVP_DigestInit_ex(mdctx, EVP_sha3_256(), NULL);
    size_t cnt;
    do {
        cnt = fread(buf, 1, BUFSIZE, fp);
        EVP_DigestUpdate(mdctx, buf, cnt);
    } while (cnt > 0);
    EVP_DigestFinal_ex(mdctx, md, NULL);
    EVP_MD_CTX_free(mdctx);
    fclose(fp);
    for (int i = 0; i < MDSIZE; ++i)
        sprintf(output + 2 * i, "%.2x", md[i]);
    printf("%s %s\n", output, path);
    lua_pushstring(L, (const char *)output);
    return 1;
}
