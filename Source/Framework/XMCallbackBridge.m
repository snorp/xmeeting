/*
 * $Id: XMCallbackBridge.m,v 1.38 2008/10/07 23:19:17 hfriederich Exp $
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

void _XMHandleCallStartInfo(const char *_callToken, XMCallEndReason endReason)
{
  NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
    
  NSString *callToken = nil;
  if (_callToken != NULL) {
    callToken = [[NSString alloc] initWithCString:_callToken encoding:NSASCIIStringEncoding];
  }
  
  [_XMOpalDispatcherSharedInstance _handleCallStartToken:callToken callEndReason:endReason];
  
  [callToken release];
  
  [autoreleasePool release];
}

void _XMHandleCallIsAlerting(const char *_callToken)
{
  NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
  
  NSString *callToken = [[NSString alloc] initWithCString:_callToken encoding:NSASCIIStringEncoding];
  
  [XMOpalDispatcher _callIsAlerting:callToken];
  
  [callToken release];
	
  [autoreleasePool release];
}

void _XMHandleIncomingCall(const char *_callToken, 
                           XMCallProtocol protocol,
                           const char *_remoteName,
                           const char *_remoteNumber,
                           const char *_remoteAddress,
                           const char *_remoteApplication,
                           const char *_localAddress)
{
  NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
  NSString *callToken = [[NSString alloc] initWithCString:_callToken encoding:NSASCIIStringEncoding];
  NSString *remoteName = [[NSString alloc] initWithCString:_remoteName encoding:NSASCIIStringEncoding];
  NSString *remoteNumber = [[NSString alloc] initWithCString:_remoteNumber encoding:NSASCIIStringEncoding];
  NSString *remoteAddress = [[NSString alloc] initWithCString:_remoteAddress encoding:NSASCIIStringEncoding];
  NSString *remoteApplication = [[NSString alloc] initWithCString:_remoteApplication encoding:NSASCIIStringEncoding];
  NSString *localAddress = [[NSString alloc] initWithCString:_localAddress encoding:NSASCIIStringEncoding];
	
  [XMOpalDispatcher _incomingCall:callToken
                         protocol:protocol
                       remoteName:remoteName
                     remoteNumber:remoteNumber
                    remoteAddress:remoteAddress
                remoteApplication:remoteApplication
                     localAddress:localAddress];

  [callToken release];
  [remoteName release];
  [remoteNumber release];
  [remoteAddress release];
  [remoteApplication release];
  [localAddress release];
	
  [autoreleasePool release];
}

void _XMHandleCallEstablished(const char *_callToken, 
                              const char *_remoteName,
                              const char *_remoteNumber,
                              const char *_remoteAddress,
                              const char *_remoteApplication,
                              const char *_localAddress)
{
  NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
  NSString *callToken = [[NSString alloc] initWithCString:_callToken encoding:NSASCIIStringEncoding];
  NSString *remoteName = [[NSString alloc] initWithCString:_remoteName encoding:NSASCIIStringEncoding];
  NSString *remoteNumber = [[NSString alloc] initWithCString:_remoteNumber encoding:NSASCIIStringEncoding];
  NSString *remoteAddress = [[NSString alloc] initWithCString:_remoteAddress encoding:NSASCIIStringEncoding];
  NSString *remoteApplication = [[NSString alloc] initWithCString:_remoteApplication encoding:NSASCIIStringEncoding];
  NSString *localAddress = [[NSString alloc] initWithCString:_localAddress encoding:NSASCIIStringEncoding];
	
  [XMOpalDispatcher _callEstablished:callToken 
                          remoteName:remoteName 
                        remoteNumber:remoteNumber
                       remoteAddress:remoteAddress
                   remoteApplication:remoteApplication
                        localAddress:localAddress];
	
  [callToken release];
  [remoteName release];
  [remoteNumber release];
  [remoteAddress release];
  [remoteApplication release];
  [localAddress release];
	
  [autoreleasePool release];
}

void _XMHandleCallCleared(const char *_callToken, XMCallEndReason endReason)
{
  NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
  
  NSString *callToken = [[NSString alloc] initWithCString:_callToken encoding:NSASCIIStringEncoding];
	
  [XMOpalDispatcher _callCleared:callToken reason:endReason];
  
  [callToken release];
	
  [autoreleasePool release];
}

void _XMHandleLocalAddress(const char *_callToken, const char *_localAddress)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
  NSString *callToken = [[NSString alloc] initWithCString:_callToken encoding:NSASCIIStringEncoding];
  NSString *localAddress = [[NSString alloc] initWithCString:_localAddress encoding:NSASCIIStringEncoding];
  
	[XMOpalDispatcher _callReleased:callToken localAddress:localAddress];
	
  [callToken release];
	[localAddress release];
	
	[autoreleasePool release];
}

void _XMHandleAudioStreamOpened(const char *_callToken, const char *_codec, bool isIncomingStream)
{
  NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
  NSString *callToken = [[NSString alloc] initWithCString:_callToken encoding:NSASCIIStringEncoding];
  NSString *codec = [[NSString alloc] initWithCString:_codec encoding:NSASCIIStringEncoding];
	
  [XMOpalDispatcher _audioStreamOpened:callToken codec:codec incoming:isIncomingStream];
	
  [callToken release];
  [codec release];
	
  [autoreleasePool release];
}

void _XMHandleVideoStreamOpened(const char *_callToken, const char *_codec, XMVideoSize videoSize, bool isIncomingStream,
                                unsigned videoWidth, unsigned videoHeight)
{
  NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
  NSString *callToken = [[NSString alloc] initWithCString:_callToken encoding:NSASCIIStringEncoding];
  NSString *codec = [[NSString alloc] initWithCString:_codec encoding:NSASCIIStringEncoding];
	
  [XMOpalDispatcher _videoStreamOpened:callToken codec:codec size:videoSize incoming:isIncomingStream width:videoWidth height:videoHeight];
	
  [callToken release];
  [codec release];
	
  [autoreleasePool release];
}

void _XMHandleAudioStreamClosed(const char *_callToken, bool isIncomingStream)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
  
  NSString *callToken = [[NSString alloc] initWithCString:_callToken encoding:NSASCIIStringEncoding];
	
	[XMOpalDispatcher _audioStreamClosed:callToken incoming:isIncomingStream];
  
  [callToken release];

	[autoreleasePool release];
}

void _XMHandleVideoStreamClosed(const char *_callToken, bool isIncomingStream)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
  
  NSString *callToken = [[NSString alloc] initWithCString:_callToken encoding:NSASCIIStringEncoding];
	
	[XMOpalDispatcher _videoStreamClosed:callToken incoming:isIncomingStream];
  
  [callToken release];
	
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

void _XMStartMediaTransmit(unsigned sessionID, XMCodecIdentifier codec, 
                           XMVideoSize videoSize, unsigned maxFramesPerSecond,
                           unsigned maxBitrate, unsigned keyframeInterval, unsigned flags)
{
  // this is called from a thread without run loop and without autorelease pool
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
  [XMMediaTransmitter _startTransmittingForSession:sessionID withCodec:codec videoSize:videoSize 
                                maxFramesPerSecond:maxFramesPerSecond maxBitrate:maxBitrate 
                                  keyframeInterval:keyframeInterval flags:flags];
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
  [_XMMediaReceiverSharedInstance _startMediaReceivingForSession:sessionID withCodec:codecIdentifier];
}

void _XMStopMediaReceiving(unsigned sessionID)
{
  [_XMMediaReceiverSharedInstance _stopMediaReceivingForSession:sessionID];
}

bool _XMProcessFrame(const char *callToken, unsigned sessionID, void *data, unsigned length)
{
  return [_XMMediaReceiverSharedInstance _decodeFrameForSession:sessionID data:data length:length callToken:callToken];
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

void _XMHandleGatekeeperRegistrationFailure(XMGatekeeperRegistrationStatus reason)
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

void _XMHandleGatekeeperRegistrationComplete()
{
  NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
  [_XMOpalDispatcherSharedInstance _handleGatekeeperRegistrationComplete];
	
  [autoreleasePool release];
}

#pragma mark -
#pragma mark SIP specific Callbacks

void _XMHandleSIPRegistration(const char *_aor)
{
  NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
    
  NSString *aor = [[NSString alloc] initWithCString:_aor encoding:NSASCIIStringEncoding];
  [_XMOpalDispatcherSharedInstance _handleSIPRegistration:aor];
  [aor release];
    
  [autoreleasePool release];
}

void _XMHandleSIPUnregistration(const char *_aor)
{
  NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
  NSString *aor = [[NSString alloc] initWithCString:_aor encoding:NSASCIIStringEncoding];
  [_XMOpalDispatcherSharedInstance _handleSIPUnregistration:aor];
  [aor release];
	
  [autoreleasePool release];
}

void _XMHandleSIPRegistrationFailure(const char *_aor, XMSIPStatusCode failReason)
{
  NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
  NSString *aor = [[NSString alloc] initWithCString:_aor encoding:NSASCIIStringEncoding];
  [_XMOpalDispatcherSharedInstance _handleSIPRegistrationFailure:aor failReason:failReason];
  [aor release];
	
  [autoreleasePool release];
}

void _XMHandleSIPRegistrationComplete()
{
  NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
  [_XMOpalDispatcherSharedInstance _handleSIPRegistrationComplete];
	
  [autoreleasePool release];
}
