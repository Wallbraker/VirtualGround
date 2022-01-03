#!/usr/bin/bash

SCRIPT_DIR=$(dirname $(readlink -f $0))

docker build -t virtual-ground:latest $SCRIPT_DIR
