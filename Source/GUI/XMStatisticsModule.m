/*
 * $Id: XMStatisticsModule.m,v 1.3 2005/06/23 12:35:57 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMStatisticsModule.h"
#import "XMMainWindowController.h"


@implementation XMStatisticsModule

- (id)init
{
	[[XMMainWindowController sharedInstance] addAdditionModule:self];
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
	return @"Call Statistics";
}

- (NSImage *)image
{
	return [NSImage imageNamed:@"Statistics"];
}

- (NSView *)contentView
{
	if(nibLoader == nil)
	{
		nibLoader = [[NSNib alloc] initWithNibNamed:@"StatisticsModule" bundle:nil];
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
