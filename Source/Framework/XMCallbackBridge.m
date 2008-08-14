/*
 * $Id: XMCallbackBridge.m,v 1.32 2008/08/14 19:57:05 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

#import "XMAudioManager.h"
#import "XMMediaTransmitter.h"
#import "XMMediaReceiver.h"
#import "XMPrivate.h"
#import "XMCallInfo.h"

#pragma mark -
#pragma mark Setup Related Callbacks

void _XMHandleSTUNInformation(XMNATType natType,
							  const char *publicAddress)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	NSString *address = [[NSString alloc] initWithCString:publicAddress encoding:NSASCIIStringEncoding];
	[_XMOpalDispatcherSharedInstance _handleNATType:natType publicAddress:address];
	[address release];
	
	[autoreleasePool release];
}

#pragma mark -
#pragma mark Call Related Callbacks

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
						   const char *remoteApplication,
						   const char *theLocalAddress)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	NSString *name = [[NSString alloc] initWithCString:remoteName encoding:NSASCIIStringEncoding];
	NSString *number = [[NSString alloc] initWithCString:remoteNumber encoding:NSASCIIStringEncoding];
	NSString *address = [[NSString alloc] initWithCString:remoteAddress encoding:NSASCIIStringEncoding];
	NSString *application = [[NSString alloc] initWithCString:remoteApplication encoding:NSASCIIStringEncoding];
	NSString *localAddress = [[NSString alloc] initWithCString:theLocalAddress encoding:NSASCIIStringEncoding];
	
	[XMOpalDispatcher _incomingCall:callID
						   protocol:protocol
						 remoteName:name
					   remoteNumber:number
					  remoteAddress:address
				  remoteApplication:application
					   localAddress:localAddress];

	[name release];
	[number release];
	[address release];
	[application release];
	[localAddress release];
	
	[autoreleasePool release];
}

void _XMHandleCallEstablished(unsigned callID, bool isIncomingCall, const char *localAddress)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	NSString *addressString = [[NSString alloc] initWithCString:localAddress encoding:NSASCIIStringEncoding];
	
	[XMOpalDispatcher _callEstablished:callID incoming:isIncomingCall localAddress:addressString];
	
	[addressString release];
	
	[autoreleasePool release];
}

void _XMHandleCallCleared(unsigned callID, XMCallEndReason endReason)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	[XMOpalDispatcher _callCleared:callID reason:endReason];
	
	[autoreleasePool release];
}

void _XMHandleLocalAddress(unsigned callID, const char *localAddress)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	NSString *addressString = [[NSString alloc] initWithCString:localAddress encoding:NSASCIIStringEncoding];
	
	[XMOpalDispatcher _callReleased:callID localAddress:addressString];
	
	[addressString release];
	
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

void _XMHandleVideoStreamOpened(unsigned callID, const char *codec, XMVideoSize videoSize, bool isIncomingStream,
								unsigned videoWidth, unsigned videoHeight)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	NSString *codecString = [[NSString alloc] initWithCString:codec encoding:NSASCIIStringEncoding];
	
	[XMOpalDispatcher _videoStreamOpened:callID codec:codecString size:videoSize incoming:isIncomingStream width:videoWidth height:videoHeight];
	
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

void _XMHandleFECCChannelOpened()
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	[XMOpalDispatcher _feccChannelOpened];
	
	[autoreleasePool release];
}

#pragma mark -
#pragma mark MediaReceiver callbacks

void _XMStartMediaTransmit(unsigned sessionID, XMCodecIdentifier codec, XMVideoSize videoSize, unsigned maxFramesPerSecond,
						   unsigned maxBitrate, unsigned keyframeInterval, unsigned flags)
{
	// this is called from a thread without run loop and without autorelease pool
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	[XMMediaTransmitter _startTransmittingForSession:sessionID withCodec:codec videoSize:videoSize maxFramesPerSecond:maxFramesPerSecond
										  maxBitrate:maxBitrate keyframeInterval:keyframeInterval flags:flags];
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

void _XMSetMaxVideoBitrate(unsigned maxVideoBitrate)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	[XMMediaTransmitter _setMaxBitrate:maxVideoBitrate];
	
	[autoreleasePool release];
}

void _XMHandleAudioInputLevel(double level)
{
	NSNumber *number = [[NSNumber alloc] initWithDouble:level];
	
	[_XMAudioManagerSharedInstance performSelectorOnMainThread:@selector(_handleAudioInputLevel:)
													withObject:number waitUntilDone:NO];
	[number release];
}

void _XMHandleAudioOutputLevel(double level)
{
	NSNumber *number = [[NSNumber alloc] initWithDouble:level];
	
	[_XMAudioManagerSharedInstance performSelectorOnMainThread:@selector(_handleAudioOutputLevel:)
													withObject:number waitUntilDone:NO];
	
	[number release];
}

void _XMHandleAudioTestEnd()
{
	[_XMAudioManagerSharedInstance performSelectorOnMainThread:@selector(_handleAudioTestEnd)
													withObject:nil waitUntilDone:NO];
}

#pragma mark -
#pragma mark H.323 specific Callbacks

void _XMHandleGatekeeperRegistration(const char *gatekeeperName, const char *gatekeeperAliases)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	NSString *name = [[NSString alloc] initWithCString:gatekeeperName encoding:NSASCIIStringEncoding];
  NSString *aliases = [[NSString alloc] initWithCString:gatekeeperAliases encoding:NSASCIIStringEncoding];
  NSArray *aliasArr = [aliases componentsSeparatedByString:@"\n"];
	[_XMOpalDispatcherSharedInstance _handleGatekeeperRegistration:name aliases:aliasArr];
	[name release];
  [aliases release];
	
	[autoreleasePool release];
}

void _XMHandleGatekeeperRegistrationFailure(XMGatekeeperRegistrationFailReason reason)
{
  NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
  
  [_XMOpalDispatcherSharedInstance _handleGatekeeperRegistrationFailure:reason];
  
  [autoreleasePool release];
}

void _XMHandleGatekeeperUnregistration()
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	[_XMOpalDispatcherSharedInstance _handleGatekeeperUnregistration];
	
	[autoreleasePool release];
}

#pragma mark -
#pragma mark SIP specific Callbacks

void _XMHandleSIPRegistration(const char *_registration)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
    
	NSString *registration = [[NSString alloc] initWithCString:_registration encoding:NSASCIIStringEncoding];
	[_XMOpalDispatcherSharedInstance _handleSIPRegistration:registration];
	[registration release];
    
	[autoreleasePool release];
}

void _XMHandleSIPUnregistration(const char *_registration)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	NSString *registration = [[NSString alloc] initWithCString:_registration encoding:NSASCIIStringEncoding];
	[_XMOpalDispatcherSharedInstance _handleSIPUnregistration:registration];
	[registration release];
	
	[autoreleasePool release];
}

void _XMHandleSIPRegistrationFailure(const char *_registration, XMSIPStatusCode failReason)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	NSString *registration = [[NSString alloc] initWithCString:_registration encoding:NSASCIIStringEncoding];
	[_XMOpalDispatcherSharedInstance _handleSIPRegistrationFailure:registration failReason:failReason];
	[registration release];
	
	[autoreleasePool release];
}

void _XMHandleSIPRegistrationSetupCompleted()
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	[_XMOpalDispatcherSharedInstance _handleRegistrationSetupCompleted];
	
	[autoreleasePool release];
}
