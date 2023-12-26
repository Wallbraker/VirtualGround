# SPDX-FileCopyrightText: 2023 Collabora, Ltd.
# SPDX-License-Identifier: CC0-1.0
FROM ubuntu:20.04

MAINTAINER Jakob Bornecrantz <jakob@collabora.com>


# Update
# Volt deps
# Special case SDL dep
# SDL dep for Charge/VirtualGround
RUN DEBIAN_FRONTEND=noninteractive apt-get -y update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install apt-utils && \
    DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install wget gdc-9 llvm-11 clang-11 lld-11 nasm git libcurl4-openssl-dev zlib1g-dev && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install libsdl2-dev

# Get AppImage tool and install
RUN wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage && \
    chmod a+x appimagetool-x86_64.AppImage && \
    mv appimagetool-x86_64.AppImage /usr/local/bin

# Install battery
RUN wget https://github.com/VoltLang/Battery/releases/download/v0.1.24/battery-0.1.24-x86_64-linux.tar.gz && \
    tar xzvf battery-0.1.24-x86_64-linux.tar.gz && \
    rm battery-0.1.24-x86_64-linux.tar.gz && \
    mv battery /usr/local/bin

ENV HOME /root/

WORKDIR $HOME

RUN mkdir volt

WORKDIR $HOME/volt

# We do this ADD to redo following steps if new commits has been added.
ADD https://api.github.com/repos/VoltLang/Volta/git/refs/heads/master version-Volta.json
ADD https://api.github.com/repos/VoltLang/Watt/git/refs/heads/master version-Watt.json
RUN git clone https://github.com/VoltLang/Volta.git && \
    git clone https://github.com/VoltLang/Watt.git

# We do this ADD to redo following steps if new commits has been added.
ADD https://api.github.com/repos/VoltLang/Charge/git/refs/heads/master version-Charge.json
RUN git clone https://github.com/VoltLang/Charge.git

# We do this ADD to redo following steps if new commits has been added.
ADD https://api.github.com/repos/Wallbraker/VirtualGround/git/refs/heads/main version-VirtualGround.json
RUN git clone --recursive https://github.com/Wallbraker/VirtualGround.git

# Do a initial build
RUN battery config Volta Watt Charge VirtualGround && \
    battery build && \
    cp VirtualGround/virtualground VirtualGround/res/appimage/VirtualGround && \
    appimagetool-x86_64.AppImage --appimage-extract-and-run VirtualGround/res/appimage

COPY describe.sh /root/volt/describe.sh
RUN \
	/root/volt/describe.sh && \
	echo Done

WORKDIR $HOME

ENTRYPOINT ["/bin/bash"]
