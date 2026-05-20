#include <lauxlib.h>
#include <openssl/evp.h>

#define BUFFER_SIZE 4096
#define DIGEST_SIZE 256/8

const char*
sha3sum(FILE *fp)
{
    static char out[2*DIGEST_SIZE];
    unsigned char buf[BUFFER_SIZE];
    unsigned char md[DIGEST_SIZE];
    EVP_MD_CTX *ctx = EVP_MD_CTX_new();
    EVP_DigestInit_ex(ctx, EVP_sha3_256(), NULL);
    size_t cnt;
    do {
        cnt = fread(buf, 1, BUFFER_SIZE, fp);
        EVP_DigestUpdate(ctx, buf, cnt);
    } while (cnt > 0);
    EVP_DigestFinal_ex(ctx, md, NULL);
    EVP_MD_CTX_free(ctx);
    fclose(fp);
    for (int i = 0; i < DIGEST_SIZE; ++i) 
        sprintf(out + 2 * i, "%.2x", md[i]);
    return (const char*) out;
}

int
ok_sha3sum(lua_State *L)
{
    const char *nm = luaL_checkstring(L, 1);
    FILE *fp = fopen(nm, "rb");
    if (!fp) {
        fprintf(stderr, "error: sha3sum: fopen\n");
        lua_pushinteger(L, -1);
        return 1;
    }
    const char* sha3 = sha3sum(fp);
    printf("%s %s\n", sha3, nm);
    lua_pushstring(L, sha3);
    return 1;
}
