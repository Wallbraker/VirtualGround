// Copyright 2018-2019, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0
/*!
 * @brief  Core using EGL and OpenXR to show content.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module charge.core.openxr.core;

import core.exception;
import core.c.stdio : fprintf, fflush, stderr;
import core.c.stdlib : exit;

import lib.gl.gl45;

import io = watt.io;

import charge.core;
import charge.core.basic;
import charge.core.openxr;
import charge.sys.resource;
import charge.sys.memheader;


class CoreOpenXR : BasicCore
{
private:
	m_running: bool;


public:
	this(mode: Mode = Mode.Normal)
	{
		gInstance = this;
		super(Flag.GFX);

		final switch (mode) {
		case Mode.Normal:
			break;
		case Mode.Headless:
			break;
		}

		setRender(null);
		setLogic(null);
		setClose(null);
		setIdle(null);

		foreach (initFunc; gInitFuncs) {
			initFunc();
		}

		m_running = true;
	}

	override fn loop() int
	{
		return 1;
	}

	override fn panic(msg: string)
	{
		io.error.writefln("panic");
		io.error.writefln("%s", msg);
		io.error.flush();
		exit(-1);
	}

	override fn getClipboardText() string
	{
		return null;
	}

	override fn screenShot()
	{
	}

	override fn resize(w: uint, h: uint, mode: WindowMode)
	{
	}

	override fn size(out w: uint, out h: uint, out mode: WindowMode)
	{
	}

	fn close()
	{
		closeDg();

		foreach (closeFunc; gCloseFuncs) {
			closeFunc();
		}

		p := Pool.opCall();
		p.collect();
		p.cleanAndLeakCheck(io.output.write);
		cMemoryPrintAll(io.output.write);
		io.output.flush();
	}
}