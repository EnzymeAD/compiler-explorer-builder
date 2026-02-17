FROM ghcr.io/enzymead/compiler-explorer-builder-compilers:main

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends curl git cron make cmake ccache clang ninja-build binutils \
    python3 python3-pip python3-venv grep build-essential zlib1g-dev \
    && apt-get autoremove -y --purge \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

RUN git clone -b main https://github.com/EnzymeAD/Enzyme.git /app/Enzyme
RUN git clone -b main https://github.com/EnzymeAD/Enzyme-JaX.git /app/Enzyme-JaX

RUN ccache -M 20G

COPY install-compilers.sh /app/install-compilers.sh
COPY install-libraries.sh /app/install-libraries.sh
COPY build-enzyme.sh /app/build-enzyme.sh
COPY build-enzyme-opt.sh /app/build-enzyme-opt.sh
COPY check-upstream.sh /app/check-upstream.sh
COPY entrypoint.sh /app/entrypoint.sh
COPY update-explorer.sh /app/update-explorer.sh
COPY crontab /etc/cron.d/crontab
COPY --from=docker:28.2-dind /usr/local/bin/docker /usr/bin/

RUN chmod +x /app/install-libraries.sh \
    && chmod +x /app/install-compilers.sh \
    && chmod +x /app/build-enzyme.sh \
    && chmod +x /app/build-enzyme-opt.sh \
    && chmod +x /app/check-upstream.sh \
    && chmod +x /app/entrypoint.sh \
    && chmod +x /app/update-explorer.sh \
    && chmod +x /etc/cron.d/crontab && crontab /etc/cron.d/crontab

WORKDIR /app

ENV DEBIAN_FRONTEND=

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["cron","-f"]
