/*
 * $Id: XMDialPadModule.m,v 1.3 2005/06/23 12:35:57 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMDialPadModule.h"
#import "XMMainWindowController.h"


@implementation XMDialPadModule

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
	return @"Dial Pad";
}

- (NSImage *)image
{
	return [NSImage imageNamed:@"DialPad"];
}

- (NSView *)contentView
{
	if(nibLoader == nil)
	{
		nibLoader = [[NSNib alloc] initWithNibNamed:@"DialPadModule" bundle:nil];
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
