/*
 * $Id: XMInCallModule.m,v 1.2 2005/06/23 12:35:57 hfriederich Exp $
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
	
	return self;
}

- (void)dealloc
{
	[nibLoader release];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	contentViewMinSize = [contentView frame].size;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_callEstablished:)
												 name:XMNotification_CallEstablished object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_callCleared:)
												 name:XMNotification_CallCleared object:nil];
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
	NSString *remoteName = [[[XMCallManager sharedInstance] activeCall] remoteName];
	[remotePartyField setStringValue:remoteName];
}

- (void)_callCleared:(NSNotification *)notif
{
	[remotePartyField setStringValue:@""];
}

@end
