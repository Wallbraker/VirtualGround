// Copyright 2018-2022, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0 or GPL-2.0-only
/*!
 * @brief  Main file, it all starts from here.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module main;

import io = watt.io;
static import ground.game;


alias wfln = io.writefln;
alias Mode = ground.game.Mode;

fn printHelp(args: string[])
{
	wfln("Usage:");
	wfln("\t%s <mode>", args[0]);
	wfln("");
	wfln("\tnormal   - VR Mode");
	wfln("\tar       - AR Mode");
	wfln("\toverlay  - Overlay mode");
	wfln("\theadless - Headless");
	io.output.flush();
}

fn parseArgs(args: string[], out mode: Mode) bool
{
	// Default to AR mode on Windows.
	version (Windows) if (args.length == 1) {
		args ~= "ar";
	}

	if (args.length == 1) {
		wfln("error: Please provide a argument");
		wfln("");
		printHelp(args);
		return false;
	}

	switch (args[1]) with (Mode) {
	case "normal": mode = Normal; break;
	case "ar": mode = Ar; break;
	case "overlay": mode = Overlay; break;
	case "headless": mode = Headless; break;
	default:
		wfln("error: Unknown argument '%s'", args[1]);
		wfln("");
		printHelp(args);
		return false;
	}

	return true;
}

fn main(args: string[]) i32
{
	mode: Mode;
	if (!parseArgs(args, out mode)) {
		return 1;
	}

	g := new ground.game.Game(mode);
	return g.loop();
}
