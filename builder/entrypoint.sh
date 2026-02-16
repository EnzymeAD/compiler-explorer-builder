#!/bin/bash

env >> /etc/environment

mv -f /app/template/config/* /app/compiler-explorer/etc/config

source /app/install-compilers.sh

source /app/install-libraries.sh

source /app/build-enzyme.sh

source /app/build-enzyme-opt.sh

source /app/update-explorer.sh

exec "$@"
