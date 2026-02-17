
# Read versions from file available in Docker volume
while read -r line || [ -n "$line" ]; do
    # format is like clang-15.0.0
    # extract the major version number
    v=$(echo "$line" | cut -d- -f2 | cut -d. -f1)

    curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
    if [ -n "$v" ]; then
        echo "Installing clang-$v..."
        apt-add-repository "deb http://apt.llvm.org/jammy/ llvm-toolchain-jammy-${v} main"
        apt-get install -y llvm-${v}-dev libomp-${v}-dev lld-${v} clang-${v} libclang-${v}-dev
    fi
done < /ver_data/clang-versions.txt
