/*
 * $Id: XMBusyModule.m,v 1.2 2006/03/16 14:13:57 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#import "XMBusyModule.h"

#import "XMMainWindowController.h"

@implementation XMBusyModule

- (id)init
{
	[[XMMainWindowController sharedInstance] addModule:self];
	
	nibLoader = nil;
	
	return self;
}

- (void)dealloc
{
	[nibLoader release];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	contentViewSize = [contentView frame].size;
}

- (NSString *)name
{
	return @"Busy";
}

- (NSView *)contentView
{
	if(nibLoader == nil)
	{
		nibLoader = [[NSNib alloc] initWithNibNamed:@"BusyModule" bundle:nil];
		[nibLoader instantiateNibWithOwner:self topLevelObjects:nil];
	}
	return contentView;
}

- (NSSize)contentViewSize
{
	[self contentView];
	
	return contentViewSize;
}

- (NSSize)contentViewMinSize
{
	[self contentView];
	
	return contentViewSize;
}

- (NSSize)contentViewMaxSize
{
	[self contentView];
	
	return contentViewSize;
}

- (NSSize)adjustResizeDifference:(NSSize)resizeDifference minimumHeight:(unsigned)minimumHeight
{
	return resizeDifference;
}

- (void)becomeActiveModule
{
	[busyIndicator startAnimation:self];
}

- (void)becomeInactiveModule
{
	[busyIndicator stopAnimation:self];
}

@end
