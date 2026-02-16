#!/bin/bash

# Compilers are located under /opt/compiler-explorer/ 
declare -a compilers=("clang-15.0.0" "clang-16.0.0" "clang-17.0.1" "clang-18.1.0" "clang-19.1.0" "clang-20.1.0" "clang-21.1.0" "clang-assertions-trunk")
declare -a branches=("main")

# Utility to insert or update key value pairs in .properties files.
setProperty () {

thekey=$1
newvalue=$2
filename=$3

if ! grep "^[#]*\s*${thekey}=.*" $filename > /dev/null; then
  echo "APPENDING because '${thekey}' not found"
  echo "$thekey=$newvalue" >> $filename
else
  echo "SETTING because '${thekey}' found already"
  escapedvalue=$(echo "$newvalue" | sed 's/\//\\\//g')
  sed -i "/${thekey}=/ s/=.*/=${escapedvalue}/" $filename
fi

}
# Create config files in a temporary directory
mkdir -p /tmp/ce
cp /app/compiler-explorer/etc/config/c++.enzyme.properties /tmp/ce/
cp /app/compiler-explorer/etc/config/c.enzyme.properties /tmp/ce/
cp /app/compiler-explorer/etc/config/llvm.enzyme.properties /tmp/ce/
cp /app/compiler-explorer/etc/config/cuda.enzyme.properties /tmp/ce/

for branch in ${branches[@]}; do
	# Checkout Enzyme
	git -C /app/Enzyme checkout $branch
	git -C /app/Enzyme fetch
	git -C /app/Enzyme reset --hard origin/$branch

	commit=$(git -C /app/Enzyme rev-parse --short=7 HEAD)

	for compiler in ${compilers[@]}; do
		version=$(echo $compiler | grep -o -E '[0-9]+|trunk' | head -1 | sed -e 's/^0\+//')
		if [ "$version" == "trunk" ]; then version="23"; fi
		semver=$(echo $compiler | sed -e "s/^clang-//" )

		mkdir -p /tmp/build/$branch/$compiler

		# Build Enzyme
		cmake -G Ninja -B /tmp/build/$branch/$compiler -S /app/Enzyme/enzyme -DCMAKE_CXX_COMPILER_LAUNCHER=ccache -DCMAKE_BUILD_TYPE=Debug -DLLVM_DIR=/opt/compiler-explorer/$compiler/lib/cmake/llvm
		cmake --build /tmp/build/$branch/$compiler
		
		# Create directories if they don't already exists and copy built plugins.
		mkdir -p /opt/compiler-explorer/$branch
		
		cp /tmp/build/$branch/$compiler/Enzyme/ClangEnzyme-$version.so /opt/compiler-explorer/$branch/ClangEnzyme-$version.so
		cp /tmp/build/$branch/$compiler/Enzyme/LLVMEnzyme-$version.so /opt/compiler-explorer/$branch/LLVMEnzyme-$version.so

		setProperty "compiler.cuclang$version-enzyme-$branch.name" "cuclang $version ($commit)" "/tmp/ce/cuda.enzyme.properties"
		setProperty "compiler.clang$version-enzyme-$branch.name" "clang $version ($commit)" "/tmp/ce/c++.enzyme.properties"
		setProperty "compiler.cclang$version-enzyme-$branch.name" "clang $version ($commit)" "/tmp/ce/c.enzyme.properties"
		setProperty "compiler.irclang$version-enzyme-$branch.name" "clang $version ($commit)" "/tmp/ce/llvm.enzyme.properties"
		setProperty "compiler.opt$version-enzyme-$branch.name" "opt $version ($commit)" "/tmp/ce/llvm.enzyme.properties"
	done
done

# Move finished config files to the final location
cp /tmp/ce/cuda.enzyme.properties /app/compiler-explorer/etc/config/
cp /tmp/ce/c++.enzyme.properties /app/compiler-explorer/etc/config/
cp /tmp/ce/c.enzyme.properties /app/compiler-explorer/etc/config/
cp /tmp/ce/llvm.enzyme.properties /app/compiler-explorer/etc/config/
