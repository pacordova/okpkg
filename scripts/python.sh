#!/bin/bash

# Cleanup
rm -fr "/usr/lib64/python3"*
okpkg purge python3

# Rebuild from source
#okpkg emerge python3 
#okpkg emerge python-{flit-core,installer,pyproject-hooks,packaging,build,wheel,setuptools}
#okpkg emerge python-{markupsafe,jinja,docutils,mako,editables,typing_extensions,setuptools-scm}
#okpkg emerge python-{pluggy,pathspec,calver,trove-classifiers,hatchling,pygments,libevdev,pyudev,ply}
#okpkg emerge glad python-pyparsing cython pyyaml meson libxml2 xcb-proto gobject-introspection glib2

# Install built binaries
cd /var/lib/okpkg/packages
okpkg install a/python3-*.tar.lz
okpkg install m/python-*.tar.lz
okpkg install \
    d/meson-*.tar.lz \
    l/libxml2-*.tar.lz \
    l/gobject-introspection-*.tar.lz \
    l/glib2-*.tar.lz \
    m/glad-*.tar.lz \
    m/cython-*.tar.lz \
    m/pyyaml-*.tar.lz \
    x/xcb-proto-*.tar.lz \
