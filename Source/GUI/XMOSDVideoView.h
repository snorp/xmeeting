/*
 * $Id: XMOSDVideoView.h,v 1.3 2006/03/14 23:06:00 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Ivan Guajana. All rights reserved.
 */

#ifndef __XM_OSD_VIDEO_VIEW_H__
#define __XM_OSD_VIDEO_VIEW_H__

#import <Cocoa/Cocoa.h>
#import "XMeeting.h"
#import "XMOnScreenControllerWindow.h"
#import "XMOnScreenControllerView.h"

#import "XMOpenGLUtilities.h"


//A NSWindow subclass which can become key window
//Used for fullscreen mode event handling
@interface XMEventAwareWindow:NSWindow
- (BOOL)canBecomeKeyWindow;
@end

/**
 * A view that draws either the local or remote
 * video or both within its frame
 * with OSD on mouse enter
 **/
@interface XMOSDVideoView : NSView <XMVideoView> {

	NSOpenGLContext *openGLContext;
	unsigned displayState;
	NSSize previousSize;
	
	// only used to draw into the window draw buffer when
	// the window does miniaturize or there is no local video
	// (e.g. when the device is changed)
	NSCIImageRep *ciRemoteImageRep;
	NSImage *noVideoImage;
	BOOL isMiniaturized;
	BOOL isBusy;
	
	// indicates that something video-related is in progress
	NSProgressIndicator *busyIndicator;
	
	//on screen display
	XMOnScreenControllerView *osd;
	XMOnScreenControllerWindow *osdControllerWindow;
	BOOL isOSDDisplayed, isMouseInView;
	NSTimer* OSDDisplayTimer;
	
	//Tracking rect (enter/exit events)
	NSTrackingRectTag trackingRect;
	
	//Last mouse position (to determine if the mouse moved)
	NSPoint lastMouseLocation;
	
	//Fullscreen stuff
	BOOL fullscreen;
	XMEventAwareWindow *fullscreenWindow;
	NSView *windowedSuperview;
	NSSize windowedSize;
	
	//Picture-in-picture stuff
	BOOL pinp;
	NSRect pinpRect;
	NSPoint downPoint; //store the distance of the mouse click from the local view's center (in classic PinP)
	Scene classicPinP, ichatPinP, sideBySidePinP, temporaryScene, noPinPScene;
	Scene *currentPinPMode;
	Scene *targetPinPMode, *initialPinPMode; //used for animation
	NSAnimation *sceneAnimation;
	
	BOOL switchedPinPMode;
	
	BOOL shouldDisplayOSD;
	
	//last volume. This should NOT be necessary (remove when muting works)
	unsigned volume;
}

- (void)startDisplayingLocalVideo;
- (void)startDisplayingRemoteVideo;
- (void)startDisplayingPinPVideo;
- (void)stopDisplayingVideo;
- (void)renderNoVideo;


/**
* Tracking mouse position
**/
- (void)mouseEntered:(NSEvent *)theEvent;
- (void)mouseExited:(NSEvent *)theEvent;

	//Get&Set
- (void)setShouldDisplayOSD:(BOOL)b;

- (void)moduleWasDeactivated:(id)module;

@end



#endif // __XM_OSD_VIDEO_VIEW_H__
