#!/usr/bin/env lua

-- This script uses a cross.tar.xz archive of the system from 
-- `scripts/cross-compile` to emulate a partial system to
-- test reproducible builds (versus a complete base)

package.cpath = package.cpath .. ";/usr/okpkg/?.so"

require "okutils"

setenv("DESTDIR", "/mnt")
chdir("/usr/okpkg/packages/base")

os.execute [[
    umount -l "$DESTDIR"
    read -p "Enter partition to format: " PART 
    mkfs.ext4 "$PART"
    mount "$PART" "$DESTDIR"

    bsdtar -C "$DESTDIR" -xf /usr/okpkg/packages/cross.tar.xz
    cp /etc/ssl/certs/ca-certificates.crt "$DESTDIR"/etc/ssl/certs
    git -C /usr/okpkg archive --prefix=okpkg/ master | 
        bsdtar -C "$DESTDIR"/usr -xf -
    cp -rp /usr/okpkg/download/* /mnt/usr/okpkg/download
]]

os.exit()

function install(pkgname)
    local cmd = [[ bsdtar -P -C "$DESTDIR" -xf "%s"-*.tar.xz ]]
    os.execute(string.format(cmd, pkgname))
end

pkgs = {
    -- ``temporary'' tools
    "bison", "perl", "libxcrypt", "zlib", "pigz", "bzip2", "expat", "python3", 
    "util-linux",
    -- partial install (modify this to the point you want to test)
    "iana-etc", "glibc", "zlib", "bzip2", "xz", "zstd", "file", "m4", "bc", 
    "flex", "pkgconf", "binutils", "gmp", "mpfr", "libmpc", "attr", "acl", 
    "libxcrypt", "gcc-libs", "gcc-13.2.0", "binutils",
}
for i=1,#pkgs do install(pkgs[i]) end
