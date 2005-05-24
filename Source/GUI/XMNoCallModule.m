/*
 * $Id: XMNoCallModule.m,v 1.1 2005/05/24 15:21:02 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMNoCallModule.h"
#import "XMMainWindowController.h"


@implementation XMNoCallModule

- (id)init
{
	[[XMMainWindowController sharedInstance] addMainModule:self];
}

- (void)dealloc
{
	[nibLoader release];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	NSLog(@"awakeFromNib, NoCallModule");
	contentViewSize = [contentView frame].size;
}

- (NSString *)name
{
	return @"NoCall";
}

- (NSView *)contentView
{
	if(nibLoader == nil)
	{
		nibLoader = [[NSNib alloc] initWithNibNamed:@"NoCallModule" bundle:nil];
		[nibLoader instantiateNibWithOwner:self topLevelObjects:nil];
	}
	return contentView;
}

- (NSSize)contentViewSize
{
	return contentViewSize;
}

- (NSSize)contentViewMinSize
{
	return contentViewSize;
}

- (BOOL)allowsContentViewResizing
{
	return NO;
}

- (void)prepareForDisplay
{
}

@end
