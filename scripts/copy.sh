#!/usr/bin/bash

docker run --name temp-virtual-ground virtual-ground:latest
docker cp temp-virtual-ground:/root/volt/VirtualGround-x86_64.AppImage .
docker rm temp-virtual-ground
