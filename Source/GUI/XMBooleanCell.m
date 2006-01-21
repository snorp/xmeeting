/*
 * $Id: XMBooleanCell.m,v 1.3 2006/01/21 23:27:00 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMBooleanCell.h"


@implementation XMBooleanCell

- (id)init
{
	self = [super init];
	
	[super setEditable:NO];
	[self setBezeled:NO];
	[self setBordered:NO];
	[self setButtonBordered:NO];
	[self setHasVerticalScroller:NO];
	[self setDrawsBackground:NO];
	
	[self setControlSize:NSSmallControlSize];
	[self setFont:[NSFont controlContentFontOfSize:12]];
	[self setIntercellSpacing:NSMakeSize(0.0, 0.0)];
	
	[self setNumberOfVisibleItems:2];
	[self addItemWithObjectValue:NSLocalizedString(@"Yes", @"YES")];
	[self addItemWithObjectValue:NSLocalizedString(@"No", @"NO")];
	
	return self;
}

- (id)objectValue
{
	NSString *string = (NSString *)[super objectValue];
	BOOL value = YES;
	
	if([string isEqualToString:NSLocalizedString(@"No", @"NO")])
	{
		value = NO;
	}
	
	return [NSNumber numberWithBool:value];
}

- (void)setObjectValue:(id<NSCopying>)obj
{
	id object = (id)obj;
	
	if([object respondsToSelector:@selector(boolValue)])
	{
		BOOL flag = [object boolValue];
		
		if(flag)
		{
			object = NSLocalizedString(@"Yes", @"YES");
		}
		else
		{
			object = NSLocalizedString(@"No", @"NO");
		}
	}
	[super setObjectValue:object];
}

- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view
{
	// we have to adjust the y-value so that the text is on the same line as a regular
	// NSTextField Cell
	frame.origin.y -= 2;
	[super drawWithFrame:frame inView:view];
}

- (BOOL)doesPopUp
{
	return [super isEnabled];
}

- (void)setDoesPopUp:(BOOL)flag
{
	[super setEnabled:flag];
}

@end
