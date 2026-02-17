#!/bin/bash

# Compilers are located under /opt/compiler-explorer/ 
declare -a compilers=("mlir-trunk")
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
cp /app/compiler-explorer/etc/config/mlir.enzyme.properties /tmp/ce/

branch="main"

commit=$(git -C /app/Enzyme-JaX rev-parse --short=7 HEAD)

for compiler in ${compilers[@]}; do
	version=$(echo $compiler | grep -o -E '[0-9]+|trunk' | head -1 | sed -e 's/^0\+//')
	# Create directories if they don't already exists and copy built plugins.
	mkdir -p /opt/compiler-explorer/$branch
		
	curl -L -o /tmp/enzyme-opt$version https://github.com/EnzymeAD/Enzyme-JAX/releases/download/nightly/enzymexlamlir-opt
	chmod +x /tmp/enzyme-opt$version
	mv /tmp/enzyme-opt$version /opt/compiler-explorer/$branch/enzyme-opt$version

	setProperty "compiler.enzyme-opt$version-$branch.name" "enzyme-opt $version ($commit)" "/tmp/ce/mlir.enzyme.properties"
done

# Move finished config files to the final location
cp /tmp/ce/mlir.enzyme.properties /app/compiler-explorer/etc/config/
