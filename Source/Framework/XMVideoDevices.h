/*
 * $Id: XMVideoDevices.h,v 1.1 2005/02/11 12:58:44 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_VIDEO_DEVICES_H__
#define __XM_VIDEO_DEVICES_H__

#include <ptlib.h>

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
