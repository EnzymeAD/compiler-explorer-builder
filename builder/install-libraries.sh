#!/bin/bash

export JULIA_DEPOT_PATH="/opt/compiler-explorer/juliapackages"
/opt/compiler-explorer/julia-1.10.*/bin/julia -e 'using Pkg; Pkg.add(["Enzyme", "Reactant"])'
/opt/compiler-explorer/julia-1.11.*/bin/julia -e 'using Pkg; Pkg.add(["Enzyme", "Reactant"])'
