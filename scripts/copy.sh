#!/usr/bin/bash
# SPDX-FileCopyrightText: 2023 Collabora, Ltd.
# SPDX-License-Identifier: CC0-1.0

docker run --name temp-virtual-ground virtual-ground:latest
docker cp temp-virtual-ground:/root/volt/VirtualGround-x86_64.AppImage .
docker rm temp-virtual-ground
