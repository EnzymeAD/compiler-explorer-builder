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

        apt-get install -y llvm-${v}-dev libomp-${v}-dev lld-${v} clang-${v} libclang-${v}-dev opt-${v}
    fi
done < /ver_data/clang-versions.txt
