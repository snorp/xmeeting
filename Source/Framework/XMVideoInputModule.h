/*
 * $Id: XMVideoInputModule.h,v 1.4 2005/10/17 12:57:53 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_VIDEO_INPUT_MODULE_H__
#define __XM_VIDEO_INPUT_MODULE_H__

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>

/**
 * This protocol declares the methods provided by
 * the VideoInput system for the modules
 **/
@protocol XMVideoInputManager <NSObject>

/**
 * In order to allow for efficient processing of the grabbed frames, the frame
 * have to reside within a CVPixelBuffer structure, encoded using the
 * k32ARGBPixelFormat. This output is automatically created as part of an 
 * ICMDecompressionSession from the SequenceGrabber data for example
 **/
- (void)handleGrabbedFrame:(CVPixelBufferRef)frame 
					  time:(TimeValue)time;

/**
 * Allows the module to set the timeScale of the
 * frames to be passed
 **/
- (void)setTimeScale:(TimeScale)timeScale;

/**
 * Tells the inputManager that the following frame timeStamps
 * start with zero again.
 **/
- (void)noteTimeStampReset;

/**
 * Allows the modules to report errors which occured during the
 * frame grabbing process. the errorCode should report which
 * error occured while the hint code may be used to indicate the place
 * where the error occured.
 * In case of an error, the module should be capable of continuing
 * anyway, do not rely on the grabbing process being aborted.
 **/
- (void)handleErrorWithCode:(ComponentResult)errorCode hintCode:(unsigned)hintCode;

@end

/**
 * This protocol declares the methods necessary for any video module to work
 * within the XMeeting framework. Since the video handling is done using
 * QuickTime, it is necessary that most of the data flow occurs withing the
 * QuickTime "world". Therefore, instances working as VideoInputModules
 * are required to return the data in the appropriate QuickTime data 
 * structures.
 * All module methods are called from a separate thread. Therefore, the
 * module should not interfere with the main thread in order to avoid 
 * race conditions.
 **/
@protocol XMVideoInputModule <NSObject>

/**
 * Returns a name appropriate for this module. This method may be called
 * on every thread, use only immutable strings here.
 **/
- (NSString *)name;

/**
 * called to allow proper initialization of the module. The module should
 * not claim any unnecessary resources before this method has been called.
 * Do not create QuickTime device lists within the initializer for example,
 * since the actual modue-manager communication happens on a different
 * thread than the main thread.
 * The manager argument is a reference to the VideoInputManager where
 * the module can send the grabbed frames to and obtain additional information.
 **/
- (void)setupWithInputManager:(id<XMVideoInputManager>)manager;

/**
 * This method is called whenever the module is no longer used and use it
 * to release any resources claimed by initModule.
 **/
- (void)close;

/**
 * Returns all devices this module is able to support. Since getting the
 * device list may be a lengthy task on some systems, the module should
 * cach the device list and only create a fresh one if refreshList ist
 * set to YES. This allows any freshly attached devices to be added to
 * the list
 **/
- (NSArray *)inputDevices;

/**
 * Tells the module to refresh it's device list (if possible)
 **/
- (void)refreshDeviceList;

/**
 * Open the device specified with inputDevice and prepare it
 * for capturing. Return the success of this operation.
 **/
- (BOOL)openInputDevice:(NSString *)inputDevice;

/**
 * Closes the device just used and cleanup any used resources
 **/
- (BOOL)closeInputDevice;

/**
 * tells the receiver to produce frames with frameSize dimension.
 * This method may be called during a ongoing grab sequence, so the receiver
 * cannot rely on having the same frame size all the time.
 * Return whether the module can support the desired size or not.
 * This method is guaranteed to be called before any call to
 * -openInputDevice is made.
 **/
- (BOOL)setInputFrameSize:(NSSize)frameSize;

/**
 * Tells the module which framerate currently is active.
 * This method may be called at any time, also during
 * active grab sessions.
 * This method is guarateed to be called before any call to
 * -openInputDevice: is made.
 * framesPerSecond is guaranteed to be greater than 0
 **/
- (void)setFrameGrabRate:(unsigned)frameGrabRate;

/**
 * Gives the module time to grab a frame.
 * Due to the different architecture which QuickTime uses,
 * it is not possible and neither desirable to have the modules
 * directly return a frame. Rather, the modules can send the data
 * using the methods of XMVideoInputManager
 **/
- (BOOL)grabFrame;

/**
 * Return a error description (localized if possible) which
 * describes errorCode. This method is guaranteed only to be
 * called on the main thread.
 **/
- (NSString *)descriptionForErrorCode:(unsigned)errorCode device:(NSString *)device;

@end

#endif // __XM_VIDEO_INPUT_MODULE_H__

