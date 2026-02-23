#!/bin/bash

source /app/install-libraries.sh

python3 /app/scripts/update-versions.py /app/data /app/template_files/etc/config /app/compiler-explorer/etc/config $(git -C /app/Enzyme rev-parse --short=7 HEAD) $(git -C /app/Enzyme-JaX rev-parse --short=7 HEAD) $(git -C /app/Reactant rev-parse --short=7 HEAD)

source /app/update-explorer.sh

exec "$@"
