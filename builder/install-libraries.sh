#!/bin/bash

export JULIA_DEPOT_PATH="/opt/compiler-explorer/juliapackages"

# Read versions from /app/data/julia-versions.txt
while read -r version; do
    # Skip empty lines
    [[ -z "$version" ]] && continue
    
    echo "Installing libraries for Julia $version..."
    /opt/compiler-explorer/julia-${version}/bin/julia -e 'using Pkg; Pkg.add(["Enzyme", "Reactant"])'
    
done < /app/data/julia-versions.txt
