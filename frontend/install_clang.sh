curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -

mkdir -p /etc/fortran
curl -fsSL https://raw.githubusercontent.com/EnzymeAD/Enzyme/main/enzyme/Fortran/enzyme_function_hooks.f90 -o /etc/fortran/enzyme_function_hooks.f90
curl -fsSL https://raw.githubusercontent.com/EnzymeAD/Enzyme/main/enzyme/Fortran/enzyme.f90 -o /etc/fortran/enzyme.f90

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
            mkdir -p /var/cache/enzyme-fortran-modules/${v}
            /usr/bin/flang-${v} -fsyntax-only -J/var/cache/enzyme-fortran-modules/${v} -I/var/cache/enzyme-fortran-modules/${v} /etc/fortran/enzyme_function_hooks.f90
            /usr/bin/flang-${v} -fsyntax-only -J/var/cache/enzyme-fortran-modules/${v} -I/var/cache/enzyme-fortran-modules/${v} /etc/fortran/enzyme.f90
        else
            apt-get install -y llvm-${v}-dev libomp-${v}-dev lld-${v} clang-${v} libclang-${v}-dev
        fi
    fi
done < /ver_data/clang-versions.txt

rm -rf /etc/fortran
