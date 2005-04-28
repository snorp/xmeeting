/*
 * $Id: XMVideoManager.h,v 1.2 2005/04/28 20:26:27 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>

#import "XMTypes.h"

extern NSString *XMNotification_DidStartVideoGrabbing;
extern NSString *XMNotification_DidStopVideoGrabbing;
extern NSString *XMNotification_DidReadVideoFrame;
extern NSString *XMNotification_DidUpdateVideoDeviceList;

@class XMLocalVideoView;

@interface XMVideoManager : NSObject {
	
	id delegate;
	
	XMLocalVideoView *view;			// The associated XMLocalVideoView (if set)
	ImageSequence drawSequence;		// Unique identifier for the draw sequence from the gWorld to the image on screen
	long imageSize;					// holder for the lengt of the image onscreen (displayed by view)
	
	SeqGrabComponent component;		// the component for SequenceGrabbing
	SGChannel channel;				// the channel for viceo data
	ImageSequence decomSequence;	// Unique identifier for the decompression sequence
	GWorldPtr gWorld;				// Pointer to the offscreen GWorld
	BOOL isGrabbing;				// indicates whether we currently are grabbing or not
	
	SGDeviceList deviceList;		// The cached deviceList
	NSArray *deviceNames;			// Storing just the device names
	
	XMVideoSize videoSize;			// The currently used video size for decompressing into GWorld
	
	//NSImage *stillImage;			// The still image to use.
	//NSBitmapImageRep *imgRep;		// The bitmap representation from the image (used to get the pixel bytes)
	
	int fps;						// indicating the framerate in which to grab video
	
	NSBitmapImageRep *remoteVideoFrame;
	
	BOOL didCallCallback;			// workaround for FW-Cam freeze bug

}

/*
 * Returns the shared instance to be used by the application.
 * XMVideoManager is a singleton object, using [[XMVideoManager alloc] init]
 * will not work.
 */
+ (XMVideoManager *)sharedInstance;

/* storage for the remote video frame */
- (NSBitmapImageRep *)remoteVideoFrame;

/**
 * Updates the device list. This may take some time, so use with care.
 */
- (void)updateDeviceList;

/* Returns the current delegate of the receiver (if any) */
- (id)delegate;

/* 
 * Sets the current delegate of the receiver. 
 * The delegate isn't retained (as this is common practice) 
 */
- (void)setDelegate:(id)delegate;

/* starts the grabbing sequence. Returns the success of this operation */
- (BOOL)startGrabbing;

/* stops the grabbing sequence */
- (void)stopGrabbing;

/* returns whether we are grabbing images or not */
- (BOOL)isGrabbing;

/* Returns a list of available video input devices, using a cached value if possible */
- (NSArray *)availableDevices;

/* 
 * Returns the selected device's name in a human understandable form.
 * This method returns values such as "iSight" and not the 
 * actual device name such as "IIDC FireWire Video"
 * Returns nil if there are no input devices
 */
- (NSString *)selectedDevice;

/*
 * Tries to select a device with deviceName as its name, returning
 * the success of this operation. Device names are the actual
 * devices's names such as "iSight" and not "IIDC FireWire Video"
 * for example
 */
- (BOOL)setSelectedDevice:(NSString *)deviceName;

/* Returns the still image from the "picture"-device */
- (NSImage *)stillImage;

/* Sets still image to use with the "picture"-device */
- (void)setStillImage:(NSImage *)image;

/* Returns the currently used frame rate */
- (int)fps;

/* Sets the frame rate to use */
- (void)setFps:(int)fps;

@end

/* 
* Methods a delecate may implement.
 * It is guaranteed that all methods will be called
 * in the main thread
 */
@interface NSObject (XMVideoManagerDelegate)

- (void)videoManagerDidStartGrabbing:(NSNotification *)notif;
- (void)videoManagerDidStopGrabbing:(NSNotification *)notif;
- (void)videoManagerDidReadVideoFrame:(NSNotification *)notif;
- (void)videoManagerDidUpdateVideoDeviceList:(NSNotification *)notif;

- (void)noteVideoManagerError:(NSString *)errorMessage code:(int)errorCode;

@end
