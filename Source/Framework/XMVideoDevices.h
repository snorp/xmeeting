/*
 * $Id: XMVideoDevices.h,v 1.2 2005/04/28 20:26:27 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_VIDEO_DEVICES_H__
#define __XM_VIDEO_DEVICES_H__

#include <ptlib.h>

class XMVideoOutputDevice : public PVideoOutputDevice
{
	PCLASSINFO(XMVideoOutputDevice, PVideoOutputDevice);
	
public:
	XMVideoOutputDevice();
	
	virtual BOOL Open(const PString & deviceName, BOOL startImmediate = TRUE);
	virtual BOOL IsOpen();
	virtual BOOL Close();
	virtual PStringList GetDeviceNames() const;
	virtual BOOL SetColourFormat(const PString & colourFormat);
	
	virtual BOOL SetFrameSize(unsigned width,
							  unsigned height);
	
	virtual PINDEX GetMaxFrameBytes();
	
	virtual BOOL SetFrameData(unsigned x,
							  unsigned y,
							  unsigned width,
							  unsigned height,
							  const BYTE * data,
							  BOOL endFrame = TRUE);
	
	virtual BOOL EndFrame();
protected:
	PBYTEArray frameStore;
	PINDEX bytesPerPixel;
	BOOL isOpen;
};

class XMVideoInputDevice : public PVideoInputDevice
{
	PCLASSINFO(XMVideoInputDevice, PVideoInputDevice);
	
public:
	XMVideoInputDevice();
	
	static PStringList GetInputDeviceNames();
	
	virtual PStringList GetDeviceNames();
	
	BOOL Start();
	BOOL Stop();
	
	BOOL Open(const PString & deviceName,
			  BOOL startImmediate = TRUE);
	
	BOOL IsOpen();
	BOOL Close();
	
	virtual BOOL IsCapturing();
	
	virtual BOOL GetFrame(PBYTEArray & frame);
    virtual BOOL GetFrameData(BYTE *buffer,                   /// Buffer to receive frame
							  PINDEX *bytesReturned = NULL);  /// Optional bytes returned.
	
    virtual BOOL GetFrameDataNoDelay (BYTE *buffer, 
									  PINDEX *bytesReturned);
	
	virtual void WaitFinishPreviousFrame();
	
    /**Get the minimum & maximum size of a frame on the device.
		
		Default behaviour returns the value 1 to UINT_MAX for both and returns
		FALSE.
		*/
    //virtual BOOL GetFrameSizeLimits(
	//								unsigned & minWidth,   /// Variable to receive minimum width
	//								unsigned & minHeight,  /// Variable to receive minimum height
	//								unsigned & maxWidth,   /// Variable to receive maximum width
	//								unsigned & maxHeight   /// Variable to receive maximum height
	//								) ;
	
	virtual BOOL TestAllFormats();
	
	//virtual PINDEX GetMaxFrameBytes();
	
};

#endif //__XM_VIDEO_DEVICES_H__
