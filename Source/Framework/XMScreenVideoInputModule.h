/*
 * $Id: XMScreenVideoInputModule.h,v 1.2 2006/02/21 22:38:59 hfriederich Exp $
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

	NSMutableArray *screenNames;	
	CGDirectDisplayID displayID;	// selected screen.
	unsigned rowBytesScreen;		// CGDisplayBytesPerRow(displayID);
	BOOL	needsUpdate;
	unsigned topLine, bottomLine;	// optimized copy only rows updated (0, height) == full screen.
	
	NSRect  frameRect;				// location on the screen (not used yet).
	
	NSSize size;					// size of image requested.
	unsigned frameGrabRate;
	CVPixelBufferRef pixelBuffer;	// buffer returned on call (can this be a screen frame buffer?).
									// Note: typedef CVBufferRef = CVImageBufferRef = CVPixelBufferRef;
}

- (id)_init;
- (void) setNeedsUpdate: (BOOL) v;
@end

#endif // __XM_SCREEN_VIDEO_INPUT_MODULE_H__
