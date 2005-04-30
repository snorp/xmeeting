/*
 * $Id: XMCallbackBridge.mm,v 1.2 2005/04/28 20:26:27 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

#import "XMAudioManager.h"
#import "XMPrivate.h"
#import "XMCallInfo.h"

void audioInputVolumeDidChange(unsigned volume)
{
	[[XMAudioManager sharedInstance] _inputVolumeDidChange:volume];
}

void audioOutputVolumeDidChange(unsigned volume)
{
	[[XMAudioManager sharedInstance] _outputVolumeDidChange:volume];
}

void noteIncomingCall(unsigned callID, 
					  XMCallProtocol protocol,
					  const char *remoteName,
					  const char *remoteNumber,
					  const char *remoteAddress,
					  const char *remoteApplication)
{
	NSString *name = [[NSString alloc] initWithCString:remoteName];
	NSString *number = [[NSString alloc] initWithCString:remoteNumber];
	NSString *address = [[NSString alloc] initWithCString:remoteAddress];
	NSString *application = [[NSString alloc] initWithCString:remoteApplication];
	
	[[XMCallManager sharedInstance] _handleIncomingCall:callID
											   protocol:protocol
											 remoteName:name
										   remoteNumber:number
										  remoteAddress:address
									  remoteApplication:application];
	
	[name release];
	[number release];
	[address release];
	[application release];
}

void noteCallEstablished(unsigned callID)
{
	[[XMCallManager sharedInstance] _handleCallEstablished:callID];
}

void noteCallCleared(unsigned callID, XMCallEndReason endReason)
{
	[[XMCallManager sharedInstance] _handleCallCleared:callID withCallEndReason:endReason];
}

void noteMediaStreamOpened(unsigned callID, bool isInputStream, const char *mediaFormat)
{
	NSString *name = [[NSString alloc] initWithCString:mediaFormat];
	
	[[XMCallManager sharedInstance] _handleMediaStreamOpened:callID 
											   isInputStream:isInputStream
												 mediaFormat:name];
}

void noteMediaStreamClosed(unsigned callID, bool isInputStream, const char *mediaFormat)
{
	// currently not implemented
}

bool noteVideoFrameUpdate(void *buffer, unsigned width, unsigned height, unsigned bytesPerPixel)
{
	return [[XMVideoManager sharedInstance] _handleVideoFrame:buffer width:width
													   height:height bytesPerPixel:bytesPerPixel];
}

bool getVideoFrame(void *buffer, unsigned *bytesReturned)
{
	return false;
}