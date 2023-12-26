#!/usr/bin/bash
# SPDX-FileCopyrightText: 2023 Collabora, Ltd.
# SPDX-License-Identifier: CC0-1.0

SCRIPT_DIR=$(dirname $(readlink -f $0))

docker build -t virtual-ground:latest $SCRIPT_DIR
