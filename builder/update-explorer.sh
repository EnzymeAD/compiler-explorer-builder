#!/bin/bash

EXPLORER_SERVICE=$(docker service ls -q --filter label=explorer)

docker service update $EXPLORER_SERVICE --force
