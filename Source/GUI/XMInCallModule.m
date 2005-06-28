/*
 * $Id: XMInCallModule.m,v 1.3 2005/06/28 20:41:06 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMeeting.h"
#import "XMInCallModule.h"
#import "XMMainWindowController.h"

@interface XMInCallModule (PrivateMethods)

- (void)_callEstablished:(NSNotification *)notif;
- (void)_callCleared:(NSNotification *)notif;

@end

@implementation XMInCallModule

- (id)init
{
	[[XMMainWindowController sharedInstance] addMainModule:self];
	
	[self contentView];
	
	return self;
}

- (void)dealloc
{
	[nibLoader release];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	NSLog(@"awakeFromNib");
	contentViewMinSize = [contentView frame].size;
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(_callEstablished:)
												 name:XMNotification_CallManagerCallEstablished object:nil];
	[notificationCenter addObserver:self selector:@selector(_callCleared:)
												 name:XMNotification_CallManagerCallCleared object:nil];
}

- (NSString *)name
{
	return @"InCall";
}

- (NSView *)contentView
{
	if(nibLoader == nil)
	{
		nibLoader = [[NSNib alloc] initWithNibNamed:@"InCallModule" bundle:nil];
		[nibLoader instantiateNibWithOwner:self topLevelObjects:nil];
	}
	return contentView;
}

- (NSSize)contentViewSize
{
	return [contentView bounds].size;
}

- (NSSize)contentViewMinSize
{
	return contentViewMinSize;
}

- (BOOL)allowsContentViewResizing
{
	return YES;
}

- (void)prepareForDisplay
{
}

#pragma mark User Interface Methods

- (void)clearCall:(id)sender
{
	[[XMCallManager sharedInstance] clearActiveCall];
}

#pragma mark Private Methods

- (void)_callEstablished:(NSNotification *)notif
{
	NSLog(@"callEstablished");
	NSString *remoteName = [[[XMCallManager sharedInstance] activeCall] remoteName];
	[remotePartyField setStringValue:remoteName];
}

- (void)_callCleared:(NSNotification *)notif
{
	[remotePartyField setStringValue:@""];
}

@end
