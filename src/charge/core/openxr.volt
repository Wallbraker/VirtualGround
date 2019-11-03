// Copyright 2018-2019, Collabora, Ltd.
// SPDX-License-Identifier: BSL-1.0
/*!
 * @brief  Core using EGL and OpenXR to show content.
 * @author Jakob Bornecrantz <jakob@collabora.com>
 */
module charge.core.openxr;

import core.exception;
import core.c.stdio : fprintf, fflush, stderr;
import core.c.stdlib : exit;

import lib.gl.gl45;

import io = watt.io;

import charge.core;
import charge.core.basic;
import charge.sys.resource;
import charge.sys.memheader;


class CoreOpenXR : BasicCore
{
private:
	m_running: bool;


public:
	this()
	{
		gInstance = this;
		super(Flag.GFX);

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

	override fn initSubSystem(flag: Flag)
	{
		throw new Exception("Flag not supported");
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
