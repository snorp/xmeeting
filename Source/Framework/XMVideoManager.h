/*
 * $Id: XMVideoManager.h,v 1.6 2005/10/11 09:03:10 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_VIDEO_MANAGER_H__
#define __XM_VIDEO_MANAGER_H__

#import <Cocoa/Cocoa.h>

#import "XMTypes.h"

@class XMLocalVideoView;

@interface XMVideoManager : NSObject {
	
	NSMutableArray *videoInputModules;
	NSMutableArray *localVideoViews;
	NSMutableArray *remoteVideoViews;
	
	NSArray *inputDevices;
	NSString *selectedInputDevice;
	
	CIImage *localVideoImage;
	NSCIImageRep *localVideoImageRep;
	BOOL doesMirrorLocalVideo;
	CGAffineTransform mirrorTransformationMatrix;
	
	CIImage *remoteVideoImage;
	NSCIImageRep *remoteVideoImageRep;
	
	unsigned transmitFrameRate;
	
	BOOL needsToStopLocalBusyIndicators;

}

/**
 * Returns the shared singleton instance of this class
 **/
+ (XMVideoManager *)sharedInstance;

/**
 * Returns an array of strings containing the input devices.
 * Note that this method does not return valid devices before
 * the appropriate Notification.
 **/
- (NSArray *)inputDevices;

/**
 * Discards the current device list and refreshes the list
 * Note that the new device list isn't available until the
 * appropriate notification is posted. Sometimes, creating
 * a new device list might take some time (1s or even more)
 **/
- (void)updateInputDeviceList;

/**
 * Returns the currently selected device
 **/
- (NSString *)selectedInputDevice;

/**
 * Sets the device to use
 **/
- (void)setSelectedInputDevice:(NSString *)inputDevice;

/**
 * Returns whether the local video is displayed
 * with the x-axis flipped or not.
 **/
- (BOOL)doesMirrorLocalVideo;

/**
 * Sets whether the local video is displayed
 * with the x-axis flipped or not
 **/
- (void)setDoesMirrorLocalVideo:(BOOL)flag;

/**
 * Returns the actual frame grab rate
 **/
- (unsigned)transmitFrameRate;

/**
 * Sets the frame grab rate
 **/
- (void)setTransmitFrameRate:(unsigned)transmitFrameRate;

/**
 * Starts the grabbing process
 **/
- (void)startGrabbing;

/**
 * Stops the grabbing process. Calling this method
 * will raise an exception if called while a transmission
 * is ongoing
 **/
- (void)stopGrabbing;

@end


#endif // __XM_VIDEO_MANAGER_H__
