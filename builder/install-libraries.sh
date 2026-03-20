#!/bin/bash

export JULIA_DEPOT_PATH="/opt/compiler-explorer/juliapackages"

# Read versions from /app/data/julia-versions.txt
while read -r version; do
    # Skip empty lines
    [[ -z "$version" ]] && continue
    
    echo "Installing libraries for Julia $version..."
    /opt/compiler-explorer/julia-${version}/bin/julia -e 'using Pkg; Pkg.add(["Enzyme", "Reactant"])'
    
done < /app/data/julia-versions.txt

export hypre_version=2.31.0

mkdir /opt/compiler-explorer/libraries

curl -L https://github.com/hypre-space/hypre/archive/refs/tags/v${hypre_version}.tar.gz > /opt/archives/hypre-v${hypre_version}.tar.gz
tar xzf hypre-v${hypre_version}.tar.gz && cd hypre-${hypre_version}/src && \
    ./configure --prefix /opt/compiler-explorer/libraries --enable-shared --disable-static && \
    make -j `nproc` && make install

# MFEM repo checkout
git clone --depth=1 https://github.com/mfem/mfem.git mfem -b v4.9
cp mfem.user.mk mfem/config/user.mk

cd mfem && make config && make -j `nproc` install