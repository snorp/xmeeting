/*
 * $Id: XMeeting.m,v 1.7 2006/02/20 17:27:48 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

#import "XMeeting.h"
#import "XMPrivate.h"
#import "XMStringConstants.h"

#import "XMSequenceGrabberVideoInputModule.h"
#import "XMDummyVideoInputModule.h"

#define XM_FRAMEWORK_NOT_INITIALIZED 0
#define XM_FRAMEWORK_INITIALIZED 1
#define XM_FRAMEWORK_CLOSE_CALLED 2
#define XM_FRAMEWORK_SEPARATE_THREADS 2

#define XM_FRAMEWORK_ALL_THREADS_CLOSED XM_FRAMEWORK_CLOSE_CALLED + XM_FRAMEWORK_SEPARATE_THREADS

unsigned _XMInitializedStatus = XM_FRAMEWORK_NOT_INITIALIZED;
XMUtils *_XMUtilsSharedInstance = nil;
XMCallManager *_XMCallManagerSharedInstance = nil;
XMCodecManager *_XMCodecManagerSharedInstance = nil;
XMAudioManager *_XMAudioManagerSharedInstance = nil;
XMVideoManager *_XMVideoManagerSharedInstance = nil;
XMOpalDispatcher *_XMOpalDispatcherSharedInstance = nil;
XMMediaTransmitter *_XMMediaTransmitterSharedInstance = nil;
XMMediaReceiver *_XMMediaReceiverSharedInstance = nil;

void XMInitFramework()
{
	if(_XMInitializedStatus == XM_FRAMEWORK_INITIALIZED)
	{
		// The Framework is already initialized
		return;
	}
	
	_XMUtilsSharedInstance = [[XMUtils alloc] _init];
	_XMCodecManagerSharedInstance = [[XMCodecManager alloc] _init];
	_XMCallManagerSharedInstance = [[XMCallManager alloc] _init];
	_XMAudioManagerSharedInstance = [[XMAudioManager alloc] _init];
	_XMVideoManagerSharedInstance = [[XMVideoManager alloc] _init];
	_XMOpalDispatcherSharedInstance = [[XMOpalDispatcher alloc] _init];
	_XMMediaTransmitterSharedInstance = [[XMMediaTransmitter alloc] _init];
	_XMMediaReceiverSharedInstance = [[XMMediaReceiver alloc] _init];
	
	// starting the OpalDispatcher Thread
	[NSThread detachNewThreadSelector:@selector(_runOpalDispatcherThread) toTarget:_XMOpalDispatcherSharedInstance withObject:nil];
	
	// starting the MediaTransmitter Thread
	[NSThread detachNewThreadSelector:@selector(_runMediaTransmitterThread) toTarget:_XMMediaTransmitterSharedInstance withObject:nil];
	
	_XMInitializedStatus = XM_FRAMEWORK_INITIALIZED;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_FrameworkDidInitialize object:nil];
}

void XMCloseFramework()
{
	if(_XMInitializedStatus != XM_FRAMEWORK_INITIALIZED)
	{
		// The Framework is already closed
		return;
	}
	
	// We call close on all and wait until all threads
	// have terminated before posting the appropriate
	// notification
	
	[_XMUtilsSharedInstance _close];
	[_XMCallManagerSharedInstance _close];
	[_XMCodecManagerSharedInstance _close];
	[_XMAudioManagerSharedInstance _close];
	[_XMVideoManagerSharedInstance _close];
	[_XMOpalDispatcherSharedInstance _close];
	[_XMMediaTransmitterSharedInstance _close];
	[_XMMediaReceiverSharedInstance _close];
	
	_XMInitializedStatus = XM_FRAMEWORK_CLOSE_CALLED;
}

void _XMThreadExit() {
	_XMInitializedStatus++;
	
	if(_XMInitializedStatus == XM_FRAMEWORK_ALL_THREADS_CLOSED)
	{
		[_XMUtilsSharedInstance release];
		_XMUtilsSharedInstance = nil;
		
		[_XMCallManagerSharedInstance release];
		_XMCallManagerSharedInstance = nil;
		
		[_XMCodecManagerSharedInstance release];
		_XMCodecManagerSharedInstance = nil;
		
		[_XMAudioManagerSharedInstance release];
		_XMAudioManagerSharedInstance = nil;
		
		[_XMVideoManagerSharedInstance release];
		_XMVideoManagerSharedInstance = nil;
		
		[_XMOpalDispatcherSharedInstance release];
		_XMOpalDispatcherSharedInstance = nil;
		
		[_XMMediaTransmitterSharedInstance release];
		_XMMediaTransmitterSharedInstance = nil;
		
		[_XMMediaReceiverSharedInstance release];
		_XMMediaTransmitterSharedInstance = nil;
		
		_XMInitializedStatus = XM_FRAMEWORK_NOT_INITIALIZED;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_FrameworkDidClose object:nil];
	}
}