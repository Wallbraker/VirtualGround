# Copyright 2023, Collabora, Ltd.
# SPDX-License-Identifier: BSL-1.0


echo -n "Volta: "
GIT_DIR=/root/volt/Volta/.git git describe --always --tags
echo -n "Watt: "
GIT_DIR=/root/volt/Watt/.git git describe --always --tags
echo -n "Charge: "
GIT_DIR=/root/volt/Charge/.git git describe --always --tags
echo -n "VirtualGround: "
GIT_DIR=/root/volt/VirtualGround/.git git describe --always --tags
