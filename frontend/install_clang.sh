
# Read versions from file available in Docker volume
while read -r line; do
    # format is like clang-15.0.0
    # extract the major version number
    v=$(echo "$line" | cut -d- -f2 | cut -d. -f1)

    if [ -n "$v" ]; then
        echo "Installing clang-$v..."
        apt-add-repository "deb http://apt.llvm.org/$(lsb_release -c | cut -f2)/ llvm-toolchain-$(lsb_release -c | cut -f2)-${v} main"
        apt-get install -y llvm-${v}-dev libomp-${v}-dev lld-${v} clang-${v} libclang-${v}-dev
    fi
done < /ver_data/clang-versions.txt
