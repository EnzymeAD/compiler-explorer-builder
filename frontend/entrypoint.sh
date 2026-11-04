#!/bin/bash
set -e

# Refresh Fortran module files from the live Enzyme checkout if available so
# module checksums always match each installed Flang binary and stay up to date.
if [ -f /opt/compiler-explorer/main/fortran/enzyme_function_hooks.f90 ] && \
   [ -f /opt/compiler-explorer/main/fortran/enzyme.f90 ]; then
    for flang_bin in /usr/bin/flang-[0-9]*; do
        [ -x "$flang_bin" ] || continue
        v="${flang_bin##*/flang-}"
        [[ "$v" =~ ^[0-9]+$ ]] || continue
        mod_dir="/var/cache/enzyme-fortran-modules/${v}"
        tmp_dir=$(mktemp -d)
        if "$flang_bin" -fsyntax-only -J"$tmp_dir" -I"$tmp_dir" \
               /opt/compiler-explorer/main/fortran/enzyme_function_hooks.f90 && \
           "$flang_bin" -fsyntax-only -J"$tmp_dir" -I"$tmp_dir" \
               /opt/compiler-explorer/main/fortran/enzyme.f90; then
            mkdir -p "$mod_dir"
            cp "$tmp_dir"/*.mod "$mod_dir"/
        else
            echo "Warning: failed to recompile Fortran modules with $flang_bin; keeping build-time modules" >&2
        fi
        rm -rf "$tmp_dir"
    done
fi

# Sync builder-rendered properties (with live commit hashes) if present
if [ -f /app/compiler-explorer/etc/config/fortran.enzyme.properties ]; then
    cp /app/compiler-explorer/etc/config/*.enzyme.properties /app/etc/config/
fi

exec node ./out/dist/app.js --static ./out/webpack/static --env enzyme "$@"
