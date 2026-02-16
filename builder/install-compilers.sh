#!/bin/bash

/app/infra/bin/ce_install --filter-match-any install "compilers/c++/clang 15.0.0" "compilers/c++/clang 16.0.0" "compilers/c++/clang 17.0.1" "compilers/c++/clang 18.1.0" "compilers/c++/clang 19.1.0" "compilers/c++/clang 20.1.0" "compilers/c++/clang 21.1.0" "compilers/c++/mlir trunk" "compilers/julia 1.10.10" "compilers/julia 1.11.9" "compilers/julia 1.12.5"

/app/infra/bin/ce_install --enable nightly install "compilers/c++/nightly/clang assertions-trunk"

/app/infra/bin/ce_install install "compilers/cuda 11.8.0"

# rust
curl -LJO https://github.com/EnzymeAD/rust/releases/download/enzyme-0.0.4/rust-nightly-x86_64-unknown-linux-gnu.tar.gz
mkdir -p /opt/compiler-explorer/rust-nightly-enzyme
tar -xf rust-nightly-x86_64-unknown-linux-gnu.tar.gz
./rust-nightly-x86_64-unknown-linux-gnu/install.sh --prefix=/opt/compiler-explorer/rust-nightly-enzyme/
rm rust-nightly-x86_64-unknown-linux-gnu.tar.gz
