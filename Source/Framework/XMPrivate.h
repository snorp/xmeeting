/*
 * $Id: XMPrivate.h,v 1.3 2005/05/24 15:21:02 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_PRIVATE_H__
#define __XM_PRIVATE_H__

#import "XMCallManager.h"
#import "XMAudioManager.h"
#import "XMVideoManager.h"
#import "XMCallInfo.h"
#import "XMTypes.h"

@class XMLocalVideoView, XMCallInfo;

@interface XMCallManager(FrameworkMethods)

/**
 * This method gets called from the CallbackBridge.
 * The call happens NOT on the main thread.
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
 * from the related callback method.
 **/
- (void)_handleIncomingCall:(XMCallInfo *)callInfo;

/**
 * This method gets called from the CallbackBridge
 * every time a call is established. The call happens
 * not on the main thread.
 */
- (void)_handleCallEstablished:(unsigned)callID;

/**
 * This method gets called on the main thread 
 * from the related callback method
 **/
- (void)_handleCallEstablished;

/**
 * This method gets called from the CallbackBridge
 * every time a call is cleared. The call happens
 * not on the main thread.
 **/
- (void)_handleCallCleared:(unsigned)callID withCallEndReason:(XMCallEndReason)endReason;

/**
 * This method gets called on the main thread
 * from the related callback method
 **/
- (void)_handleCallCleared:(NSNumber *)callEndReason;

/**
 * This method gets called from the CallbackBridge
 * every time a media stream is opened. The call
 * happens not on the main thread.
 **/
- (void)_handleMediaStreamOpened:(unsigned)callID 
				   isInputStream:(BOOL)isInputStream 
					 mediaFormat:(NSString *)mediaFormat;

/**
 * This method gets called on the main thread
 * from the related callback method
 **/
- (void)_handleMediaStreamOpened:(NSArray *)values;

/**
 * This method gets called from the CallbackBridge
 * every time a media stream is closed. The call
 * happens not on the main thread.
 **/
- (void)_handleMediaStreamClosed:(unsigned)callID
				   isInputStream:(BOOL)isInputStream
					 mediaFormat:(NSString *)mediaFormat;

@end

@interface XMAudioManager(FrameworkMethods)

- (void)_inputVolumeDidChange:(unsigned)volume;
- (void)_outputVolumeDidChange:(unsigned)volume;

@end

@interface XMVideoManager(FrameworkMethods)

- (void)_addLocalVideoView:(XMLocalVideoView *)view;
- (void)_removeLocalVideoView:(XMLocalVideoView *)view;
- (void)_drawToView:(XMLocalVideoView *)view;

- (BOOL)_handleVideoFrame:(void *)buffer width:(unsigned)width
				   height:(unsigned)height bytesPerPixel:(unsigned)bytesPerPixel;

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
- (void)_setRemoteName:(NSString *)remoteName;
- (void)_setRemoteNumber:(NSString *)remoteNumber;
- (void)_setRemoteAddress:(NSString *)remoteAddress;
- (void)_setRemoteApplication:(NSString *)remoteApplication;
- (void)_setIncomingAudioCodec:(NSString *)codec;
- (void)_setOutgoingAudioCodec:(NSString *)codec;
- (void)_setIncomingVideoCodec:(NSString *)codec;
- (void)_setOutgoingVideoCodec:(NSString *)codec;

@end

#endif // __XM_PRIVATE_H__
