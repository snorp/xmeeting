/*
 * $Id: XMPrivate.h,v 1.1 2005/02/11 12:58:44 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMCallManager.h"
#import "XMAudioManager.h"
#import "XMVideoManager.h"
#import "XMCallInfo.h"
#import "XMTypes.h"

@class XMLocalVideoView, XMCallInfo;

@interface XMCallManager(FrameworkMethods)

/**
 * This method gets called from the CallbackBridge
 * and is NOT called on the main thread.
 * Calls _handleIncomingCall: on the main thread
 **/
- (void)_handleIncomingCall:(unsigned)callID
				   protocol:(XMCallProtocol)protocol
				 remoteName:(NSString *)remoteName 
			   remoteNumber:(NSString *)remoteNumber
			  remoteAddress:(NSString *)remoteAddress
		  remoteApplication:(NSString *)remoteApplication;

/**
 * This method gets called on the main thread
 **/
- (void)_handleIncomingCall:(XMCallInfo *)callInfo;

/**
 * This method gets called from the CallbackBridge
 * every time a call is established. This happens
 * NOT on the main thread.
 */
- (void)_handleCallEstablished:(unsigned)callID;

/**
 * This method gets called from the CallbackBridge
 * every time a call is cleared. This is not called
 * on the main thread.
 **/
- (void)_handleCallCleared:(unsigned)callID withCallEndReason:(XMCallEndReason)endReason;

@end

@interface XMAudioManager(FrameworkMethods)

- (void)_inputVolumeDidChange:(unsigned)volume;
- (void)_outputVolumeDidChange:(unsigned)volume;

@end

@interface XMVideoManager(FrameworkMethods)

- (void)_addLocalVideoView:(XMLocalVideoView *)view;
- (void)_removeLocalVideoView:(XMLocalVideoView *)view;
- (void)_drawToView:(XMLocalVideoView *)view;

- (void)_getFrameData:(void *)frameBuffer;

@end

@interface XMCallInfo (FrameworkMethods)

- (id)_initWithCallID:(unsigned)callID 
			   protocol:(XMCallProtocol)protocol
			 remoteName:(NSString *)remoteName
		   remoteNumber:(NSString *)remoteNumber
		  remoteAddress:(NSString *)remoteAddress
	  remoteApplication:(NSString *)remoteApplication
			 callStatus:(XMCallStatus)status;

- (unsigned)_callID;

- (void)_setCallStatus:(XMCallStatus)status;
- (void)_setCallEndReason:(XMCallEndReason)endReason;

@end
