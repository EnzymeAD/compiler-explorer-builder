# syntax=docker/dockerfile:1.19

FROM ubuntu:24.04 AS build_deps

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      binutils \
      build-essential \
      ccache \
      clang \
      lld \
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

# Compilers directly supported by Compiler Explorer
FROM infra AS compilers_9
RUN /app/infra/bin/ce_install --filter-match-any install \
    "compilers/julia 1.10.0"
FROM infra AS compilers_10
RUN /app/infra/bin/ce_install --filter-match-any install \
    "compilers/julia 1.11.2"
    
# Do *NOT* do the nightly clang here, or it will immediately get out
# of date.
FROM infra AS compilers_11
RUN /app/infra/bin/ce_install install \
    "compilers/cuda 12.9.1"

FROM infra AS libraries
RUN /app/infra/bin/ce_install --filter-match-any install \
    "libraries/c++/boost 1.82.0" \
    "libraries/c++/mfem 4.7" \
    "libraries/c++/nlohmann_json 3.11.1" \
    "libraries/c++/eigen 3.4.0"
RUN mkdir -p /opt/compiler-explorer/libs && \
    curl -fsSL "https://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-3.19.4.tar.gz" | \
    tar -C /opt/compiler-explorer/libs -zx -f -

FROM infra AS complete
LABEL org.opencontainers.image.source=https://github.com/EnzymeAD/compiler-explorer-builder
LABEL org.opencontainers.image.description="Compilers for Enzyme Explorer"
COPY --link --from=compilers_9 /opt/compiler-explorer /opt/compiler-explorer
COPY --link --from=compilers_10 /opt/compiler-explorer /opt/compiler-explorer
COPY --link --from=compilers_11 /opt/compiler-explorer /opt/compiler-explorer
COPY --link --from=libraries /opt/compiler-explorer /opt/compiler-explorer
WORKDIR /app
ENTRYPOINT ["/bin/false"]
