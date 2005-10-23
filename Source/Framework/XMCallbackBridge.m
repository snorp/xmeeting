/*
 * $Id: XMCallbackBridge.m,v 1.6 2005/10/23 19:59:00 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

#import "XMAudioManager.h"
#import "XMMediaTransmitter.h"
#import "XMMediaReceiver.h"
#import "XMPrivate.h"
#import "XMCallInfo.h"

void _XMHandleCallIsAlerting(unsigned callID)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	[XMOpalDispatcher _callIsAlerting:callID];
	
	[autoreleasePool release];
}

void _XMHandleIncomingCall(unsigned callID, 
						   XMCallProtocol protocol,
						   const char *remoteName,
						   const char *remoteNumber,
						   const char *remoteAddress,
						   const char *remoteApplication)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	NSString *name = [[NSString alloc] initWithCString:remoteName];
	NSString *number = [[NSString alloc] initWithCString:remoteNumber];
	NSString *address = [[NSString alloc] initWithCString:remoteAddress];
	NSString *application = [[NSString alloc] initWithCString:remoteApplication];
	
	[XMOpalDispatcher _incomingCall:callID
						   protocol:protocol
						 remoteName:name
					   remoteNumber:number
					  remoteAddress:address
				  remoteApplication:application];

	[name release];
	[number release];
	[address release];
	[application release];
	
	[autoreleasePool release];
}

void _XMHandleCallEstablished(unsigned callID, bool isIncomingCall)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	[XMOpalDispatcher _callEstablished:callID incoming:isIncomingCall];
	
	[autoreleasePool release];
}

void _XMHandleCallCleared(unsigned callID, XMCallEndReason endReason)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	[XMOpalDispatcher _callCleared:callID reason:endReason];
	
	[autoreleasePool release];
}

void _XMHandleMediaStreamOpened(unsigned callID, bool isIncomingStream, const char *mediaFormat)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	NSString *name = [[NSString alloc] initWithCString:mediaFormat];
	
	[XMOpalDispatcher _mediaStreamOpened:callID codec:name incoming:isIncomingStream];
	
	[name release];
	
	[autoreleasePool release];
}

void _XMHandleMediaStreamClosed(unsigned callID, bool isIncomingStream, const char *mediaFormat)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	NSString *name = [[NSString alloc] initWithCString:mediaFormat];
	
	[XMOpalDispatcher _mediaStreamClosed:callID codec:name incoming:isIncomingStream];
	
	[name release];
	
	[autoreleasePool release];
}

#pragma mark MediaReceiver callbacks

void _XMStartMediaTransmit(unsigned codec, XMVideoSize videoSize, unsigned maxFramesPerSecond,
						   unsigned maxBitrate, unsigned sessionID)
{
	// this is called from a thread without run loop and without autorelease pool
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	[XMMediaTransmitter _startTransmittingWithCodec:codec videoSize:videoSize maxFramesPerSecond:maxFramesPerSecond
										 maxBitrate:maxBitrate session:sessionID];
	
	[autoreleasePool release];
}

void _XMStopMediaTransmit(unsigned sessionID)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	[XMMediaTransmitter _stopTransmittingForSession:sessionID];
	
	[autoreleasePool release];
}

void _XMStartMediaReceiving(unsigned codecType, unsigned payloadType, XMVideoSize videoSize, unsigned sessionID)
{
	[_XMMediaReceiverSharedInstance _startMediaReceivingWithCodec:codecType 
													  payloadType:payloadType 
														videoSize:videoSize 
														  session:sessionID];
}

void _XMStopMediaReceiving(unsigned sessionID)
{
	[_XMMediaReceiverSharedInstance _stopMediaReceivingForSession:sessionID];
}

bool _XMProcessPacket(void *packetData, unsigned length, unsigned sessionID)
{
	return [_XMMediaReceiverSharedInstance _processPacket:packetData length:length session:sessionID];
}

void _XMUpdatePicture()
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	[XMMediaTransmitter _updatePicture];
	
	[autoreleasePool release];
}

#pragma mark H.323 specific Callbacks

void _XMHandleGatekeeperRegistration(const char *gatekeeperName)
{
	NSString *name = [[NSString alloc] initWithCString:gatekeeperName];
	[_XMOpalDispatcherSharedInstance _handleGatekeeperRegistration:name];
	[name release];
}

void _XMHandleGatekeeperUnregistration()
{
	[_XMOpalDispatcherSharedInstance _handleGatekeeperUnregistration];
}