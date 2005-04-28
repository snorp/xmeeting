/*
 * $Id: XMVideoDevices.cpp,v 1.2 2005/04/28 20:26:27 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include <ptlib.h>
#include <ptlib/videoio.h>
#include <ptlib/vconvert.h>

#include "XMVideoDevices.h"
#include "XMCallbackBridge.h"

XMVideoOutputDevice::XMVideoOutputDevice()
{
	colourFormat = "RGB24";
	bytesPerPixel = 3;
	frameStore.SetSize(frameWidth * frameHeight * bytesPerPixel);
	
	cout << "creating xm video output device " << endl;
	
	isOpen = FALSE;
}

BOOL XMVideoOutputDevice::Open(const PString & name, BOOL startImmediate)
{
	Close();
	
	deviceName = name;
	
	isOpen = TRUE;
	
	return TRUE;
}

BOOL XMVideoOutputDevice::IsOpen()
{
	return isOpen;
}

BOOL XMVideoOutputDevice::Close()
{
	isOpen = FALSE;
	
	return TRUE;
}

PStringList XMVideoOutputDevice::GetDeviceNames() const
{
	PStringList list;
	list += "XMVideo";
	return list;
}

BOOL XMVideoOutputDevice::SetColourFormat(const PString & colourFormat)
{
	if(colourFormat == "RGB32")
	{
		bytesPerPixel = 4;
	}
	else if(colourFormat == "RGB24")
	{
		bytesPerPixel = 3;
	}
	else
	{
		return FALSE;
	}
	
	return PVideoOutputDevice::SetColourFormat(colourFormat) && SetFrameSize(frameWidth, frameHeight);
}

BOOL XMVideoOutputDevice::SetFrameSize(unsigned width, unsigned height)
{
	if(!PVideoOutputDevice::SetFrameSize(width, height))
	{
		return FALSE;
	}
	
	return frameStore.SetSize(frameWidth*frameHeight*bytesPerPixel);
}

PINDEX XMVideoOutputDevice::GetMaxFrameBytes()
{
	return frameStore.GetSize();
}

BOOL XMVideoOutputDevice::SetFrameData(unsigned x, unsigned y,
									   unsigned width, unsigned height,
									   const BYTE * data,
									   BOOL endFrame)
{
	if (x+width > frameWidth || y+height > frameHeight)
	{
		return FALSE;
	}
	
	if (x == 0 && width == frameWidth && y == 0 && height == frameHeight) 
	{
		if (converter != NULL)
			converter->Convert(data, frameStore.GetPointer());
		else
			memcpy(frameStore.GetPointer(), data, height*width*bytesPerPixel);
	}
	else 
	{
		if (converter != NULL) 
		{
			PAssertAlways("Converted output of partial RGB frame not supported");
			return FALSE;
		}
		
		if (x == 0 && width == frameWidth)
		{
			memcpy(frameStore.GetPointer() + y*width*bytesPerPixel, data, height*width*bytesPerPixel);
		}
		else 
		{
			for (unsigned dy = 0; dy < height; dy++)
			{
				memcpy(frameStore.GetPointer() + ((y+dy)*width + x)*bytesPerPixel,
					   data + dy*width*bytesPerPixel, width*bytesPerPixel);
			}
		}
	}
	
	if(endFrame)
	{
		return EndFrame();
	}
	
	return TRUE;
}

BOOL XMVideoOutputDevice::EndFrame()
{
	return noteVideoFrameUpdate((void *)frameStore.GetPointer(), frameWidth, frameHeight, bytesPerPixel);
}

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