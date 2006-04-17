/*
 * $Id: XMCallbackBridge.m,v 1.18 2006/04/17 17:51:22 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
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
	
	NSString *name = [[NSString alloc] initWithCString:remoteName encoding:NSASCIIStringEncoding];
	NSString *number = [[NSString alloc] initWithCString:remoteNumber encoding:NSASCIIStringEncoding];
	NSString *address = [[NSString alloc] initWithCString:remoteAddress encoding:NSASCIIStringEncoding];
	NSString *application = [[NSString alloc] initWithCString:remoteApplication encoding:NSASCIIStringEncoding];
	
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

void _XMHandleAudioStreamOpened(unsigned callID, const char *codec, bool isIncomingStream)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	NSString *codecString = [[NSString alloc] initWithCString:codec encoding:NSASCIIStringEncoding];
	
	[XMOpalDispatcher _audioStreamOpened:callID codec:codecString incoming:isIncomingStream];
	
	[codecString release];
	
	[autoreleasePool release];
}

void _XMHandleVideoStreamOpened(unsigned callID, const char *codec, XMVideoSize videoSize, bool isIncomingStream)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	NSString *codecString = [[NSString alloc] initWithCString:codec encoding:NSASCIIStringEncoding];
	
	[XMOpalDispatcher _videoStreamOpened:callID codec:codecString size:videoSize incoming:isIncomingStream];
	
	[codecString release];
	
	[autoreleasePool release];
}

void _XMHandleAudioStreamClosed(unsigned callID, bool isIncomingStream)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	[XMOpalDispatcher _audioStreamClosed:callID incoming:isIncomingStream];

	[autoreleasePool release];
}

void _XMHandleVideoStreamClosed(unsigned callID, bool isIncomingStream)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	[XMOpalDispatcher _videoStreamClosed:callID incoming:isIncomingStream];
	
	[autoreleasePool release];
}

#pragma mark MediaReceiver callbacks

void _XMStartMediaTransmit(unsigned sessionID, XMCodecIdentifier codec, XMVideoSize videoSize, unsigned maxFramesPerSecond,
						   unsigned maxBitrate, unsigned flags)
{
	// this is called from a thread without run loop and without autorelease pool
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	[XMMediaTransmitter _startTransmittingForSession:sessionID withCodec:codec videoSize:videoSize maxFramesPerSecond:maxFramesPerSecond
										  maxBitrate:maxBitrate flags:flags];
	[autoreleasePool release];
}

void _XMStopMediaTransmit(unsigned sessionID)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	[XMMediaTransmitter _stopTransmittingForSession:sessionID];
	
	[autoreleasePool release];
}

void _XMStartMediaReceiving(unsigned sessionID, XMCodecIdentifier codecIdentifier)
{
	[_XMMediaReceiverSharedInstance _startMediaReceivingForSession:sessionID
														 withCodec:codecIdentifier];
}

void _XMStopMediaReceiving(unsigned sessionID)
{
	[_XMMediaReceiverSharedInstance _stopMediaReceivingForSession:sessionID];
}

bool _XMProcessFrame(unsigned sessionID, void *data, unsigned length)
{
	return [_XMMediaReceiverSharedInstance _decodeFrameForSession:sessionID
															 data:data
														   length:length];
}

void _XMHandleH264SPSAtomData(void *data, unsigned length)
{
	[_XMMediaReceiverSharedInstance _handleH264SPSAtomData:data length:length];
}

void _XMHandleH264PPSAtomData(void *data, unsigned length)
{
	[_XMMediaReceiverSharedInstance _handleH264PPSAtomData:data length:length];
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
	NSString *name = [[NSString alloc] initWithCString:gatekeeperName encoding:NSASCIIStringEncoding];
	[_XMOpalDispatcherSharedInstance _handleGatekeeperRegistration:name];
	[name release];
}

void _XMHandleGatekeeperUnregistration()
{
	[_XMOpalDispatcherSharedInstance _handleGatekeeperUnregistration];
}

#pragma mark SIP specific Callbacks

void _XMHandleSIPRegistration(const char *theHost, const char *theUsername)
{
	NSString *host = [[NSString alloc] initWithCString:theHost encoding:NSASCIIStringEncoding];
	NSString *username = [[NSString alloc] initWithCString:theUsername encoding:NSASCIIStringEncoding];
	[_XMOpalDispatcherSharedInstance _handleSIPRegistrationForHost:host username:username];
	[host release];
	[username release];
}

void _XMHandleSIPUnregistration(const char *theHost, const char *theUsername)
{
	NSString *host = [[NSString alloc] initWithCString:theHost encoding:NSASCIIStringEncoding];
	NSString *username = [[NSString alloc] initWithCString:theUsername encoding:NSASCIIStringEncoding];
	[_XMOpalDispatcherSharedInstance _handleSIPUnregistrationForHost:host username:username];
	[host release];
	[username release];
}

void _XMHandleSIPRegistrationFailure(const char *theHost, const char *theUsername, XMSIPStatusCode failReason)
{
	NSString *host = [[NSString alloc] initWithCString:theHost encoding:NSASCIIStringEncoding];
	NSString *username = [[NSString alloc] initWithCString:theUsername encoding:NSASCIIStringEncoding];
	[_XMOpalDispatcherSharedInstance _handleSIPRegistrationFailureForHost:host username:username failReason:failReason];
	[host release];
	[username release];
}

void _XMHandleRegistrarSetupCompleted()
{
	[_XMOpalDispatcherSharedInstance _handleRegistrarSetupCompleted];
}