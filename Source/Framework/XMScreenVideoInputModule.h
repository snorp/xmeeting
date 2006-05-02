/*
 * $Id: XMScreenVideoInputModule.h,v 1.5 2006/05/02 06:58:18 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Mark Fleming. All rights reserved.
 */

/*!
	@header XMScreenVideoInputModule.h
	@discussion	XMVideoInputManager screen capture implementation, 
	
	Creates a CVPixelBuffer and is called X time per sec to get updates.
	CGRemoteApplication update callback is created to get update areas.
	
	grabFrame routine does the update via: 
		[inputManager handleGrabbedFrame:pixelBuffer time:timeStamp];
			
*/

#ifndef __XM_SCREEN_VIDEO_INPUT_MODULE_H__
#define __XM_SCREEN_VIDEO_INPUT_MODULE_H__

#import <Cocoa/Cocoa.h>
#import "XMVideoInputModule.h"

@interface XMScreenVideoInputModule : NSObject <XMVideoInputModule> {

	id<XMVideoInputManager> inputManager;

	NSMutableArray *screenNames;	// array containing the names for all screens
	
	CGDirectDisplayID displayID;	// selected screen.
	NSRect screenRect;
	unsigned rowBytesScreen;		// number of bytes per row for the selected screen
	BOOL	needsUpdate;			// used to indicate whether the screen did change or not
	unsigned topLine, bottomLine;	// optimized copy only rows updated (0, height) == full screen.
	OSType screenPixelFormat;		// pixel format of the screen
	
	NSLock *updateLock;				// assuring correct propagation of screen updates
	
	NSRect  frameRect;				// location on the screen (not used yet).
	
	XMVideoSize videoSize;			// required size of output image.
	
	CVPixelBufferRef pixelBuffer;	// buffer returned on call to -grabFrame
	void *imageBuffer;				// copy of screen buffer (for performance reasons)
	void *imageCopyContext;			// context used to copy the image
	
	unsigned droppedFrameCounter;	// counter to ensure that at least every 5th frame is transmitted
	
	BOOL locked;					// used to prevent accessing the screen while a configuration change is ongoing
	BOOL needsDisposing;			// indicates that the buffers need to be disposed
}

- (id)_init;

@end

#endif // __XM_SCREEN_VIDEO_INPUT_MODULE_H__
