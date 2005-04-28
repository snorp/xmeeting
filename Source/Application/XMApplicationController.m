/*
 * $Id: XMApplicationController.m,v 1.1 2005/04/28 20:26:26 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMApplicationController.h"
#import "XMAudioManager.h"
#import "XMVideoManager.h"
#import "XMLocalVideoView.h"
#import "XMCallManager.h"
#import "XMCallInfo.h"

#import "XMPreferencesWindowController.h"

@implementation XMApplicationController

- (void)awakeFromNib
{
	[[XMCallManager sharedInstance] setDelegate:self];
	[[XMVideoManager sharedInstance] setDelegate:self];
}

- (void)callManagerDidReceiveIncomingCall:(NSNotification *)notif
{
	XMCallInfo *callInfo = [[XMCallManager sharedInstance] activeCall];
	int result = NSRunAlertPanel(@"IncomingCall", [callInfo remoteName], @"Accept", @"Deny", nil);
	
	[remotePartyField setStringValue:[callInfo remoteName]];
	[extraField setStringValue:@"Incoming call"];
	
	if(result == NSOKButton)
	{
		[[XMCallManager sharedInstance] acceptIncomingCall:YES];
	}
	else
	{
		[[XMCallManager sharedInstance] acceptIncomingCall:NO];
	}
}

- (void)callManagerDidEstablishCall:(NSNotification *)notif
{
	XMCallInfo *callInfo = [[XMCallManager sharedInstance] activeCall];
	
	[extraField setStringValue:@"Call Established"];
	[callButton setTitle:@"Clear"];
}

- (void)callManagerDidEndCall:(NSNotification *)notif
{
	XMCallInfo *callInfo = [[XMCallManager sharedInstance] activeCall];
	
	[extraField setStringValue:@"Call Ended"];
	[callButton setTitle:@"Call"];
}

- (IBAction)callButtonPressed:(id)sender
{
	if([[callButton title] isEqualToString:@"Call"])
	{
		[[XMCallManager sharedInstance] callRemoteParty:[addressField stringValue] 
										  usingProtocol:XMCallProtocol_H323];
	}
	else
	{
		[[XMCallManager sharedInstance] clearActiveCall];
	}
}

- (void)applicationDidFinishLaunching:(NSNotification *)notif
{
	[[XMPreferencesWindowController sharedInstance] showPreferencesWindow];
	//[videoView startDisplayingLocalVideo];
	//[[XMVideoManager sharedInstance] startGrabbing];
}

- (void)videoManagerDidReadVideoFrame:(NSNotification *)notif
{
	NSBitmapImageRep *frame = [[XMVideoManager sharedInstance] remoteVideoFrame];
	
	NSImage *oldImage = [remoteView image];
	
	NSImage *newImage = [[NSImage alloc] init];
	[newImage addRepresentation:frame];
	
	[remoteView setImage:newImage];
	[newImage release];
}

@end
