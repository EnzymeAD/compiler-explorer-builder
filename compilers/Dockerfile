# syntax=docker/dockerfile:1.19

FROM ubuntu:24.04 AS build_deps

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      binutils \
      build-essential \
      ccache \
      clang \
      cmake \
      cron \
      curl \
      git \
      make \
      ninja-build \
      python3 \
      python3-pip \
      python3-venv \
      zlib1g-dev \
    && apt-get autoremove -y --purge \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

FROM build_deps AS infra

COPY infra /app/infra
RUN make -C /app/infra ce

FROM infra AS compilers
# Compilers directly supported by Compiler Explorer
RUN /app/infra/bin/ce_install --filter-match-any install \
    "compilers/c++/clang 15.0.0" \
    "compilers/c++/clang 16.0.0" \
    "compilers/c++/clang 17.0.1" \
    "compilers/c++/clang 18.1.0" \
    "compilers/c++/clang 19.1.0" \
    "compilers/c++/clang 20.1.0" \
    "compilers/c++/clang 21.1.0" \
    "compilers/julia 1.10.0" \
    "compilers/julia 1.11.9" \
    "compilers/julia 1.12.5"
    
# Do *NOT* do the nightly clang here, or it will immediately get out
# of date.
RUN /app/infra/bin/ce_install install \
    "compilers/cuda 12.9.1"

FROM compilers AS libraries
RUN /app/infra/bin/ce_install --filter-match-any install \
    "libraries/c++/boost 1.82.0" \
    "libraries/c++/mfem 4.7" \
    "libraries/c++/nlohmann_json 3.11.1" \
    "libraries/c++/eigen 3.4.0"
RUN mkdir -p /opt/compiler-explorer/libs && \
    curl -fsSL "https://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-3.19.4.tar.gz" | \
    tar -C /opt/compiler-explorer/libs -zx -f -

LABEL org.opencontainers.image.source=https://github.com/EnzymeAD/compiler-explorer-builder
LABEL org.opencontainers.image.description="Compilers for Enzyme Explorer"
WORKDIR /app
ENTRYPOINT ["/bin/false"]
