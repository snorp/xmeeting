/*
 * $Id: XMVideoDevices.cpp,v 1.1 2005/02/11 12:58:44 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include <ptlib.h>

#include "XMVideoDevices.h"

XMVideoInputDevice::XMVideoInputDevice()
{
}

PStringList XMVideoInputDevice::GetInputDeviceNames()
{
	PStringList list;
	list += "XMVideo";
	return list;
}

PStringList XMVideoInputDevice::GetDeviceNames()
{
	return GetInputDeviceNames();
}

BOOL XMVideoInputDevice::Start()
{
	return TRUE;
}

BOOL XMVideoInputDevice::Stop()
{
	return TRUE;
}

BOOL XMVideoInputDevice::Open(const PString & deviceName,
							  BOOL startImmediate)
{
	return TRUE;
}

BOOL XMVideoInputDevice::IsOpen()
{
	return TRUE;
}

BOOL XMVideoInputDevice::Close()
{
	return TRUE;
}

BOOL XMVideoInputDevice::IsCapturing()
{
	return TRUE;
}

BOOL XMVideoInputDevice::GetFrame(PBYTEArray & frame)
{
	return FALSE;
}

BOOL XMVideoInputDevice::GetFrameData(BYTE * buffer, PINDEX * bytesReturned)
{
	return FALSE;
}

BOOL XMVideoInputDevice::GetFrameDataNoDelay(BYTE *buffer, PINDEX *bytesReturned)
{
	return FALSE;
}

void XMVideoInputDevice::WaitFinishPreviousFrame()
{
}

BOOL XMVideoInputDevice::TestAllFormats()
{
	return TRUE;
}