/*
 * $Id: XMCallInfo.m,v 1.1 2005/02/11 12:58:44 hfriederich Exp $
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

- (NSString *)incomingAudioCodec
{
	return incomingAudioCodec;
}

- (NSString *)outgoingAudioCodec
{
	return outgoingAudioCodec;
}

#pragma mark Setter Methods

- (void)_setCallStatus:(XMCallStatus)status
{
	callStatus = status;
}

- (void)_setCallEndReason:(XMCallEndReason)endReason
{
	callEndReason = endReason;
}

@end
