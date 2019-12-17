// Copyright 2018-2019, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0 or GPL-2.0-only
/*!
 * @brief  Main file, it all starts from here.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module main;

import ground.game;


fn main(args: string[]) i32
{
	g := new WindowGame(args);
	return g.loop();
}
