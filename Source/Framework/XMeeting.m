/*
 * $Id: XMeeting.m,v 1.16 2007/09/25 12:12:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>

#import "XMeeting.h"
#import "XMPrivate.h"
#import "XMStringConstants.h"

#define XM_FRAMEWORK_NOT_INITIALIZED 0
#define XM_FRAMEWORK_INITIALIZING 1
#define XM_FRAMEWORK_INITIALIZED 2
#define XM_FRAMEWORK_CLOSE_CALLED 3

#define XM_FRAMEWORK_SEPARATE_THREADS 3

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
XMCallRecorder *_XMCallRecorderSharedInstance = nil;

void XMInitFramework(NSString *pTracePath)
{
  if(_XMInitializedStatus == XM_FRAMEWORK_INITIALIZING ||
     _XMInitializedStatus == XM_FRAMEWORK_INITIALIZED)
  {
    // The Framework is already initialized
    return;
  }
  
  _XMInitializedStatus = XM_FRAMEWORK_INITIALIZING;
  
  _XMCallManagerSharedInstance = [[XMCallManager alloc] _initWithPTracePath:pTracePath];
}

void _XMLaunchFramework(NSString *pTracePath)
{
  // Set the PWLIBPLUGINDIR environment variable to the plugins directory of XMeeting, or PWLib
  // will search the entire filesystem for pugins before starting up...
  NSBundle *bundle = [NSBundle bundleForClass:[XMCallManager class]];
  NSString *pluginsPath = [[bundle resourcePath] stringByAppendingPathComponent:@"Plugins"];
  const char *string = [pluginsPath cStringUsingEncoding:NSUTF8StringEncoding];
  setenv("PWLIBPLUGINDIR", string, 1);
  
  // Entering QuickTime
  EnterMovies();
  
  _XMUtilsSharedInstance = [[XMUtils alloc] _init];
  _XMAudioManagerSharedInstance = [[XMAudioManager alloc] _init];
  _XMVideoManagerSharedInstance = [[XMVideoManager alloc] _init];
  _XMOpalDispatcherSharedInstance = [[XMOpalDispatcher alloc] _init];
  _XMMediaTransmitterSharedInstance = [[XMMediaTransmitter alloc] _init];
  _XMMediaReceiverSharedInstance = [[XMMediaReceiver alloc] _init];
  _XMCallRecorderSharedInstance = [[XMCallRecorder alloc] _init];
  
  // starting the OpalDispatcher Thread
  [NSThread detachNewThreadSelector:@selector(_runOpalDispatcherThread:) toTarget:_XMOpalDispatcherSharedInstance withObject:pTracePath];
  
  // starting the MediaTransmitter Thread
  [NSThread detachNewThreadSelector:@selector(_runMediaTransmitterThread) toTarget:_XMMediaTransmitterSharedInstance withObject:nil];
  
  while (_XMInitializedStatus != XM_FRAMEWORK_INITIALIZED)
  {
    usleep(10000);
  }
  
  // This has to be done after the framework has initialized since the list of available codecs
  // has to be determined
  _XMCodecManagerSharedInstance = [[XMCodecManager alloc] _init];
  
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
  
  _XMInitializedStatus = XM_FRAMEWORK_CLOSE_CALLED;
  
  [_XMUtilsSharedInstance _close];
  [_XMCallManagerSharedInstance _close];
  [_XMCodecManagerSharedInstance _close];
  [_XMAudioManagerSharedInstance _close];
  [_XMVideoManagerSharedInstance _close];
  [_XMOpalDispatcherSharedInstance _close];
  [_XMMediaTransmitterSharedInstance _close];
  [_XMMediaReceiverSharedInstance _close];
  [_XMCallRecorderSharedInstance _close];
}

void _XMSubsystemInitialized()
{
  _XMInitializedStatus = XM_FRAMEWORK_INITIALIZED;
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
    
    usleep(200000);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_FrameworkDidClose object:nil];
  }
}