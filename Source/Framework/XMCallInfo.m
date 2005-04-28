/*
 * $Id: XMCallInfo.m,v 1.2 2005/04/28 20:26:26 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMCallInfo.h"
#import "XMPrivate.h"


@implementation XMCallInfo

#pragma mark Init & Deallocation Methods

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)_initWithCallID:(unsigned)theID 
			 protocol:(XMCallProtocol)theProtocol
		   remoteName:(NSString *)theRemoteName 
		 remoteNumber:(NSString *)theRemoteNumber
		remoteAddress:(NSString *)theRemoteAddress
	remoteApplication:(NSString *)theRemoteApplication
		   callStatus:(XMCallStatus)theStatus;
{
	self = [super init];
	
	callID = theID;
	protocol = theProtocol;
	
	remoteName = [theRemoteName copy];
	remoteNumber = [theRemoteNumber copy];
	remoteAddress = [theRemoteAddress copy];
	remoteApplication = [theRemoteApplication copy];
	callStatus = theStatus;
	
	// setting the end reason to an impossible value
	callEndReason = XMCallEndReasonCount;
	
	incomingAudioCodec = nil;
	outgoingAudioCodec = nil;
	incomingVideoCodec = nil;
	outgoingVideoCodec = nil;
	
	return self;
}

- (void)dealloc
{
	[remoteName release];
	[remoteNumber release];
	[remoteAddress release];
	[remoteApplication release];
	
	[incomingAudioCodec release];
	[outgoingAudioCodec release];
	[incomingVideoCodec release];
	[outgoingVideoCodec release];
	
	[super dealloc];
}

#pragma mark Accessor Methods

- (unsigned)_callID
{
	return callID;
}

- (XMCallProtocol)protocol
{
	return protocol;
}

- (NSString *)remoteName
{
	return remoteName;
}

- (NSString *)remoteNumber
{
	return remoteNumber;
}

- (NSString *)remoteAddress
{
	return remoteAddress;
}

- (NSString *)remoteApplication
{
	return remoteApplication;
}

- (XMCallStatus)callStatus
{
	return callStatus;
}

- (NSString *)incomingAudioCodec
{
	return incomingAudioCodec;
}

- (NSString *)outgoingAudioCodec
{
	return outgoingAudioCodec;
}

- (NSString *)incomingVideoCodec
{
	return incomingVideoCodec;
}

- (NSString *)outgoingVideoCodec
{
	return outgoingVideoCodec;
}

#pragma mark Setter Methods

- (void)_setRemoteName:(NSString *)theName
{
	NSString *old = remoteName;
	remoteName = [theName copy];
	[old release];
}

- (void)_setRemoteNumber:(NSString *)theNumber
{
	NSString *old = remoteNumber;
	remoteNumber = [theNumber copy];
	[old release];
}

- (void)_setRemoteAddress:(NSString *)theAddress
{
	NSString *old = remoteAddress;
	remoteAddress = [theAddress copy];
	[old release];
}

- (void)_setRemoteApplication:(NSString *)theApplication
{
	NSString *old = remoteApplication;
	remoteApplication = [theApplication copy];
	[old release];
}

- (void)_setCallStatus:(XMCallStatus)status
{
	callStatus = status;
}

- (void)_setCallEndReason:(XMCallEndReason)endReason
{
	callEndReason = endReason;
}

- (void)_setIncomingAudioCodec:(NSString *)codec
{
	NSString *old = incomingAudioCodec;
	incomingAudioCodec = [codec copy];
	[old release];
}

- (void)_setOutgoingAudioCodec:(NSString *)codec
{
	NSString *old = outgoingAudioCodec;
	outgoingAudioCodec = [codec copy];
	[old release];
}

- (void)_setIncomingVideoCodec:(NSString *)codec
{
	NSString *old = incomingVideoCodec;
	incomingVideoCodec = [codec copy];
	[old release];
}

- (void)_setOutgoingVideoCodec:(NSString *)codec
{
	NSString *old = outgoingVideoCodec;
	outgoingVideoCodec = [codec copy];
	[old release];
}

@end
