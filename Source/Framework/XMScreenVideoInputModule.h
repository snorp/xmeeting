/*
 * $Id: XMScreenVideoInputModule.h,v 1.6 2007/05/08 10:49:54 hfriederich Exp $
 *
 * Copyright (c) 2006-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2007 Mark Fleming, Hannes Friederich. All rights reserved.
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
#import "XMAreaSelectionView.h"

@class XMScreenSelectionView;

@interface XMScreenVideoInputModule : NSObject <XMVideoInputModule> {

	id<XMVideoInputManager> inputManager;

	NSMutableArray *screenNames;	// array containing the names for all screens
	
	CGDirectDisplayID displayID;	// selected screen.
	NSRect screenRect;
	unsigned rowBytesScreen;		// number of bytes per row for the selected screen
	BOOL	needsUpdate;			// used to indicate whether the screen did change or not
	unsigned topLine, bottomLine;	// optimized copy only rows updated (0, height) == full screen.
	OSType screenPixelFormat;		// pixel format of the screen
    NSRect screenAreaRect;
	
	NSLock *updateLock;				// assuring correct propagation of screen updates
	
	XMVideoSize videoSize;			// required size of output image.
	
	CVPixelBufferRef pixelBuffer;	// buffer returned on call to -grabFrame
	void *imageBuffer;				// copy of screen buffer (for performance reasons)
	void *imageCopyContext;			// context used to copy the image
	
	unsigned droppedFrameCounter;	// counter to ensure that at least every 5th frame is transmitted
	
	BOOL locked;					// used to prevent accessing the screen while a configuration change is ongoing
	BOOL needsDisposing;			// indicates that the buffers need to be disposed
    
    IBOutlet NSView *settingsView;
    IBOutlet XMScreenSelectionView * selectionView;
    void *overviewCopyContext;
    CVPixelBufferRef overviewBuffer;
    NSBitmapImageRep *overviewImageRep;
    BOOL updateSelectionView;
    int overviewCounter;
}

- (id)_init;

@end

@interface XMScreenSelectionView : XMAreaSelectionView
{
    XMScreenVideoInputModule *inputModule;
}

- (void)setInputModule:(XMScreenVideoInputModule *)inputModule;

@end

#endif // __XM_SCREEN_VIDEO_INPUT_MODULE_H__
