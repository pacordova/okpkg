#!/bin/lua

dofile("/bin/okpkg")
unpack = unpack or table.unpack
local C = dofile("/etc/okpkg.conf")
local ok = require("okutils")

-- Cleanup
--ok.remove_all("/usr/lib64/python3.14")
--ok.remove_all("/opt/python3.13")
--ok.remove_all("/opt/python3.12")
--ok.remove_all("/opt/python")
--os.remove("/bin/pyproject-build")
--os.remove("/bin/wheel")
--os.remove("/bin/meson")
--os.remove("/usr/share/man/man1/meson.1")
--os.remove("/usr/share/polkit-1/actions/com.mesonbuild.install.policy")

-- Bootstrap
--purge("python")
--install("/var/cache/ok/pkg/python-3.13.13-skylake.tar.lz")
--ok.symlink("/opt/python3.13/bin/python3.13", "/bin/python3.13")
--ok.symlink("/opt/python3.13/lib/libpython3.13.so.1.0", "/lib64/libpython3.13.so.1.0")

purge("python-flit-core")
download("python-flit-core")
os.execute("$python -m flit_core.wheel")
os.execute("$python bootstrap_install.py dist/*.whl")

purge("python-installer")
download("python-installer")
os.execute("$python -m flit_core.wheel")
os.execute("cd src && $python -m installer ../dist/*.whl")

purge("python-pyproject-hooks")
download("python-pyproject-hooks")
os.execute("$python -m flit_core.wheel")
os.execute("$python -m installer dist/*.whl")

purge("python-packaging")
download("python-packaging")
os.execute("$python -m flit_core.wheel")
os.execute("$python -m installer dist/*.whl")

purge("python-build")
download("python-build")
os.execute("$python -m flit_core.wheel")
os.execute("$python -m installer dist/*.whl")

purge("python-wheel")
download("python-wheel")
os.execute("$python -m build -nx")
os.execute("$python -m installer dist/*whl")

purge("python-setuptools")
download("python-setuptools")
os.execute("$python -m build -nx")
os.execute("$python -m installer dist/*whl")

purge("meson")
download("meson")
os.execute("$python -m build -nx")
os.execute("$python -m installer dist/*whl")
