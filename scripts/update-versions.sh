#!/bin/bash

# Compilers are located under /opt/compiler-explorer/ 

compilers=()
while IFS= read -r line || [[ -n "$line" ]]; do
    compilers+=("$line")
done < data/clang-versions.txt

trunk_version=$(cat data/trunk-llvm-version.txt)

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
	  sed -i.bak "/${thekey}=/ s/=.*/=${escapedvalue}/" $filename
	fi
}

# Create config files in a temporary directory
mkdir -p /tmp/ce

cp frontend/files/etc/config/c++.enzyme.properties /tmp/ce/
cp frontend/files/etc/config/c.enzyme.properties /tmp/ce/
cp frontend/files/etc/config/llvm.enzyme.properties /tmp/ce/
cp frontend/files/etc/config/cuda.enzyme.properties /tmp/ce/

for branch in ${branches[@]}; do

	# Initialize empty strings for the compiler lists
  list_cuclang=""
  list_clang=""
  list_cclang=""
  list_irclang=""
  list_opt=""

  for compiler in "${compilers[@]}"; do
			version=$(echo $compiler | grep -o -E '[0-9]+|trunk' | head -1 | sed -e 's/^0\+//')
			if [ "$version" == "trunk" ]; then version="$trunk_version"; fi
      
      # Append to the strings with a colon separator
      list_cuclang="${list_cuclang:+$list_cuclang:}cuclang$version-enzyme-$branch"
      list_clang="${list_clang:+$list_clang:}clang$version-enzyme-$branch"
      list_cclang="${list_cclang:+$list_cclang:}cclang$version-enzyme-$branch"
      list_irclang="${list_irclang:+$list_irclang:}irclang$version-enzyme-$branch"
      list_opt="${list_opt:+$list_opt:}opt$version-enzyme-$branch"
  done

	setProperty "group.cuclang-enzyme-$branch.compilers" "$list_cuclang" "/tmp/ce/cuda.enzyme.properties"
  setProperty "group.clang-enzyme-$branch.compilers" "$list_clang" "/tmp/ce/c++.enzyme.properties"
  setProperty "group.clang-enzyme-$branch.compilers" "$list_cclang" "/tmp/ce/c.enzyme.properties"
  setProperty "group.clang-enzyme-$branch.compilers" "$list_irclang" "/tmp/ce/llvm.enzyme.properties"
  setProperty "group.opt-enzyme-$branch.compilers" "$list_opt" "/tmp/ce/llvm.enzyme.properties"

	setProperty "group.clang-enzyme-$branch.intelAsm" "-mllvm --x86-asm-syntax=intel" "/tmp/ce/c++.enzyme.properties"
	setProperty "group.clang-enzyme-$branch.intelAsm" "-mllvm --x86-asm-syntax=intel" "/tmp/ce/c.enzyme.properties"
	setProperty "group.clang-enzyme-$branch.intelAsm" "-mllvm --x86-asm-syntax=intel" "/tmp/ce/llvm.enzyme.properties"

	setProperty "group.cuclang-enzyme-$branch.compilerType" "clang-cuda" "/tmp/ce/cuda.enzyme.properties"
	setProperty "group.clang-enzyme-$branch.compilerType" "clang" "/tmp/ce/c++.enzyme.properties"
	setProperty "group.clang-enzyme-$branch.compilerType" "clang" "/tmp/ce/c.enzyme.properties"
	setProperty "group.clang-enzyme-$branch.compilerType" "clang" "/tmp/ce/llvm.enzyme.properties"
	setProperty "group.opt-enzyme-$branch.compilerType" "opt" "/tmp/ce/llvm.enzyme.properties"

	setProperty "group.cuclang-enzyme-$branch.supportsExecute" "false" "/tmp/ce/cuda.enzyme.properties"
	setProperty "group.clang-enzyme-$branch.supportsExecute" "true" "/tmp/ce/c++.enzyme.properties"
	setProperty "group.clang-enzyme-$branch.supportsExecute" "true" "/tmp/ce/c.enzyme.properties"
	setProperty "group.clang-enzyme-$branch.supportsExecute" "true" "/tmp/ce/llvm.enzyme.properties"	
	setProperty "group.opt-enzyme-$branch.supportsExecute" "false" "/tmp/ce/llvm.enzyme.properties"

	setProperty "group.clang-enzyme-$branch.isSemVer" "true" "/tmp/ce/c++.enzyme.properties"
	setProperty "group.clang-enzyme-$branch.isSemVer" "true" "/tmp/ce/c.enzyme.properties"
	setProperty "group.clang-enzyme-$branch.isSemVer" "true" "/tmp/ce/llvm.enzyme.properties"
	setProperty "group.opt-enzyme-$branch.isSemVer" "true" "/tmp/ce/llvm.enzyme.properties"

	setProperty "group.cuclang.groupName" "CUCLANG + ENZYME ($branch)" "/tmp/ce/cuda.enzyme.properties"
	setProperty "group.clang-enzyme-$branch.groupName" "CLANG + ENZYME ($branch)" "/tmp/ce/c++.enzyme.properties"
	setProperty "group.clang-enzyme-$branch.groupName" "CLANG + ENZYME ($branch)" "/tmp/ce/c.enzyme.properties"
	setProperty "group.clang-enzyme-$branch.groupName" "CLANG + ENZYME ($branch)" "/tmp/ce/llvm.enzyme.properties"
	setProperty "group.opt-enzyme-$branch.groupName" "OPT + ENZYME ($branch)" "/tmp/ce/llvm.enzyme.properties"

	setProperty "group.clang-enzyme-$branch.options" "-fno-discard-value-names" "/tmp/ce/c++.enzyme.properties"
	setProperty "group.clang-enzyme-$branch.options" "-fno-discard-value-names" "/tmp/ce/c.enzyme.properties"
	setProperty "group.clang-enzyme-$branch.options" "-fno-discard-value-names" "/tmp/ce/llvm.enzyme.properties"


	for compiler in ${compilers[@]}; do
		echo "compiler=$compiler"
		version=$(echo $compiler | grep -o -E '[0-9]+|trunk' | head -1 | sed -e 's/^0\+//')
		if [ "$version" == "trunk" ]; then version="$trunk_version"; fi
		semver=$(echo $compiler | sed -e "s/^clang-//" )
		commit="unknown"

		setProperty "compiler.cuclang$version-enzyme-$branch.exe" "/opt/compiler-explorer/$compiler/bin/clang++" "/tmp/ce/cuda.enzyme.properties"
		setProperty "compiler.clang$version-enzyme-$branch.exe" "/opt/compiler-explorer/$compiler/bin/clang++" "/tmp/ce/c++.enzyme.properties"
		setProperty "compiler.cclang$version-enzyme-$branch.exe" "/opt/compiler-explorer/$compiler/bin/clang" "/tmp/ce/c.enzyme.properties"
		setProperty "compiler.irclang$version-enzyme-$branch.exe" "/opt/compiler-explorer/$compiler/bin/clang" "/tmp/ce/llvm.enzyme.properties"
		setProperty "compiler.opt$version-enzyme-$branch.exe" "/opt/compiler-explorer/$compiler/bin/opt" "/tmp/ce/llvm.enzyme.properties"

		setProperty "compiler.cuclang$version-enzyme-$branch.options" "-fplugin=/opt/compiler-explorer/$branch/ClangEnzyme-$version.so" "/tmp/ce/cuda.enzyme.properties"
		setProperty "compiler.clang$version-enzyme-$branch.options" "-fplugin=/opt/compiler-explorer/$branch/ClangEnzyme-$version.so" "/tmp/ce/c++.enzyme.properties"
		setProperty "compiler.cclang$version-enzyme-$branch.options" "-fplugin=/opt/compiler-explorer/$branch/ClangEnzyme-$version.so" "/tmp/ce/c.enzyme.properties"
		setProperty "compiler.irclang$version-enzyme-$branch.options" "-fpass-plugin=/opt/compiler-explorer/$branch/ClangEnzyme-$version.so" "/tmp/ce/llvm.enzyme.properties"
		
		if [ $version -ge 17 ] 
		then
		setProperty "compiler.opt$version-enzyme-$branch.options" "-load-pass-plugin=/opt/compiler-explorer/$branch/LLVMEnzyme-$version.so -load=/opt/compiler-explorer/$branch/LLVMEnzyme-$version.so -passes=enzyme --enzyme-attributor=0" "/tmp/ce/llvm.enzyme.properties"
 
		elif [ $version -ge 16 ] 
		then
		setProperty "compiler.opt$version-enzyme-$branch.options" "-load-pass-plugin=/opt/compiler-explorer/$branch/LLVMEnzyme-$version.so -load=/opt/compiler-explorer/$branch/LLVMEnzyme-$version.so -passes=enzyme -opaque-pointers=0 --enzyme-attributor=0" "/tmp/ce/llvm.enzyme.properties"

		else
		setProperty "compiler.opt$version-enzyme-$branch.options" "-load-pass-plugin=/opt/compiler-explorer/$branch/LLVMEnzyme-$version.so -load=/opt/compiler-explorer/$branch/LLVMEnzyme-$version.so -enzyme --enzyme-attributor=0" "/tmp/ce/llvm.enzyme.properties"
		fi

		setProperty "compiler.cuclang$version-enzyme-$branch.semver" "$semver" "/tmp/ce/c++.enzyme.properties"
		setProperty "compiler.clang$version-enzyme-$branch.semver" "$semver" "/tmp/ce/c++.enzyme.properties"
		setProperty "compiler.cclang$version-enzyme-$branch.semver" "$semver" "/tmp/ce/c.enzyme.properties"
		setProperty "compiler.irclang$version-enzyme-$branch.semver" "$semver" "/tmp/ce/llvm.enzyme.properties"
		setProperty "compiler.opt$version-enzyme-$branch.semver" "$semver" "/tmp/ce/llvm.enzyme.properties"
	done
done

# Move finished config files to the final location
cp /tmp/ce/cuda.enzyme.properties frontend/files/etc/config/
cp /tmp/ce/c++.enzyme.properties frontend/files/etc/config/
cp /tmp/ce/c.enzyme.properties frontend/files/etc/config/
cp /tmp/ce/llvm.enzyme.properties frontend/files/etc/config/
