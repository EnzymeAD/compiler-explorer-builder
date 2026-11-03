curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -

# Read versions from file available in Docker volume
while read -r line || [ -n "$line" ]; do
    # format is like clang-15.0.0
    # extract the major version number
    v=$(echo "$line" | cut -d- -f2 | cut -d. -f1)

    if [ -n "$v" ]; then
        # Determine distro based on version
        if [ "$v" -lt 17 ]; then
            distro="jammy"
        else
            distro="noble"
        fi

        echo "Installing clang-$v using $distro..."

        # Use the variable to construct the repository string
        apt-add-repository "deb http://apt.llvm.org/${distro}/ llvm-toolchain-${distro}-${v} main"

        if [ "$v" -ge 20 ]; then
            apt-get install -y llvm-${v}-dev libomp-${v}-dev lld-${v} clang-${v} libclang-${v}-dev flang-${v}
            mkdir -p /usr/local/include/enzyme-fortran-${v} /var/cache/enzyme-fortran-modules/${v}
            /usr/bin/flang-${v} -fsyntax-only -J/usr/local/include/enzyme-fortran-${v} -I/usr/local/include/enzyme-fortran-${v} /etc/fortran/enzyme_function_hooks.f90
            /usr/bin/flang-${v} -fsyntax-only -J/usr/local/include/enzyme-fortran-${v} -I/usr/local/include/enzyme-fortran-${v} /etc/fortran/enzyme.f90
            cp /usr/local/include/enzyme-fortran-${v}/*.mod /var/cache/enzyme-fortran-modules/${v}/
        else
            apt-get install -y llvm-${v}-dev libomp-${v}-dev lld-${v} clang-${v} libclang-${v}-dev
        fi
    fi
done < /ver_data/clang-versions.txt
