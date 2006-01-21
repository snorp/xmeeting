/*
 * $Id: XMZeroConfModule.m,v 1.6 2006/01/21 23:27:00 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMZeroConfModule.h"
#import "XMMainWindowController.h"


@implementation XMZeroConfModule

- (id)init
{
	[[XMMainWindowController sharedInstance] addAdditionModule:self];
	
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
	return @"Bonjour";
}

- (NSImage *)image
{
	return [NSImage imageNamed:@"ZeroConf"];
}

- (NSView *)contentView
{
	if(nibLoader == nil)
	{
		nibLoader = [[NSNib alloc] initWithNibNamed:@"ZeroConfModule" bundle:nil];
		[nibLoader instantiateNibWithOwner:self topLevelObjects:nil];
	}
	
	return contentView;
}

- (NSSize)contentViewSize
{
	// if not already done, causing the nib file to load
	[self contentView];
	
	return contentViewSize;
}

- (void)becomeActiveModule
{
}

- (void)becomeInactiveModule
{
}

- (BOOL)isResizableWhenInSeparateWindow
{
	return YES;
}

@end
