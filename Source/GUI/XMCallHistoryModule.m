/*
 * $Id: XMCallHistoryModule.m,v 1.1 2005/05/24 15:21:02 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMCallHistoryModule.h"


@implementation XMCallHistoryModule

- (id)init
{
	[[XMMainWindowController sharedInstance] addBottomModule:self];
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
	return @"Call History";
}

- (NSImage *)image
{
	return nil;
}

- (NSView *)contentView
{
	if(nibLoader == nil)
	{
		nibLoader = [[NSNib alloc] initWithNibNamed:@"CallHistoryModule" bundle:nil];
		[nibLoader instantiateNibWithOwner:self topLevelObjects:nil];
	}
	
	return contentView;
}

- (NSSize)contentViewSize
{
	return contentViewSize;
}

- (void)prepareForDisplay
{
}

@end