/*
 * $Id: XMInCallView.m,v 1.7 2006/03/16 14:13:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMInCallView.h"

#define TOP_CONTENT_MARGIN 15
#define BOTTOM_CONTENT_MARGIN 15
#define LEFT_CONTENT_MARGIN 4
#define RIGHT_CONTENT_MARGIN 4
#define CONTENT_SPACING 2

@interface XMInCallView (PrivateMethods)

- (void)_validateContentViews;
- (void)_layoutContent:(NSRect)frame;

@end

@implementation XMInCallView

#pragma mark Init & Deallocation Methods

- (void)awakeFromNib
{
	[self addSubview:videoContentView];
	[self addSubview:statusContentView];
	//[self addSubview:buttonContentView];
	[self setAutoresizesSubviews:NO];
	
	NSRect statusContentFrame = [statusContentView frame];
	//NSRect buttonContentFrame = [buttonContentView frame];
	statusContentHeight = statusContentFrame.size.height;
	//buttonContentHeight = buttonContentFrame.size.height;
	buttonContentHeight = 0;
	minContentWidth = statusContentFrame.size.width;
	
	videoSize = XMVideoSize_CIF;
	
	showVideoContent = NO;
	
	statusContentFrame.origin.x = LEFT_CONTENT_MARGIN;
	[statusContentView setFrame:statusContentFrame];
	
	//buttonContentFrame.origin.x = LEFT_CONTENT_MARGIN;
	//buttonContentFrame.origin.y = BOTTOM_CONTENT_MARGIN;
	//[buttonContentView setFrame:buttonContentFrame];
	
	[self _validateContentViews];
	
	NSRect frame = [self frame];
	frame.size = [self minimumSize];
	[self setFrame:frame];
}

#pragma mark Public Methods

- (void)setShowVideoContent:(BOOL)flag
{
	showVideoContent = flag;
	
	if (!flag){ //no video
		videoSize = XMVideoSize_320_240;
		showVideoContent = YES;
	}
	
	[self _validateContentViews];
}

- (void)setVideoSize:(XMVideoSize)theVideoSize
{
	videoSize = theVideoSize;
}

- (NSSize)minimumSize
{
	unsigned width;
	unsigned height;
	
	width = LEFT_CONTENT_MARGIN + minContentWidth + RIGHT_CONTENT_MARGIN;
	height = TOP_CONTENT_MARGIN + BOTTOM_CONTENT_MARGIN;
	
	if(showVideoContent == YES)
	{
		NSSize theVideoSize = XMGetVideoFrameDimensions(videoSize);
		
		if((unsigned)theVideoSize.width > minContentWidth)
		{
			width = LEFT_CONTENT_MARGIN + (unsigned)theVideoSize.width + RIGHT_CONTENT_MARGIN;
		}
		
		height += (unsigned)theVideoSize.height;
	}
	return NSMakeSize(width, height);
}

- (NSSize)preferredSize
{
	if(showVideoContent == NO)
	{
		NSLog(@"returning minSize");
		return [self minimumSize];
	}
	
	NSSize currentSize = [self frame].size;
	NSSize requiredSize = XMGetVideoFrameDimensions(videoSize);
	unsigned width = currentSize.width;
	
	if(width < (unsigned)requiredSize.width)
	{
		return [self minimumSize];
	}
	unsigned contentWidth = width - LEFT_CONTENT_MARGIN - RIGHT_CONTENT_MARGIN;
	
	unsigned videoHeight = XMGetVideoHeightForWidth(contentWidth, XMVideoSize_CIF);

	unsigned preferredHeight = BOTTOM_CONTENT_MARGIN + videoHeight + TOP_CONTENT_MARGIN;

	return NSMakeSize(width, preferredHeight);
}

- (NSSize)maximumSize
{
	if(showVideoContent == NO)
	{
		return [self minimumSize];
	}
	
	// we do not return FLT_MAX since this might cause overflow
	// and wrong results
	return NSMakeSize(20000, 20000);
}

- (NSSize)adjustResizeDifference:(NSSize)resizeDifference minimumHeight:(unsigned)minimumHeight
{
	if(showVideoContent == NO)
	{
		return resizeDifference;
	}
	
	NSSize ownSize = [self bounds].size;
	
	unsigned usedHeight = (TOP_CONTENT_MARGIN + BOTTOM_CONTENT_MARGIN);
	
	int minimumVideoHeight = minimumHeight - usedHeight;
	
	int availableWidth = (int)ownSize.width + (int)resizeDifference.width - LEFT_CONTENT_MARGIN - RIGHT_CONTENT_MARGIN;
	int availableHeight = (int)ownSize.height + (int)resizeDifference.height - usedHeight;
	
	int calculatedWidth = (int)XMGetVideoWidthForHeight(availableHeight, XMVideoSize_CIF);
	int calculatedHeight = (int)XMGetVideoHeightForWidth(availableWidth, XMVideoSize_CIF);
	
	if(calculatedHeight <= minimumVideoHeight)
	{
		// the height set to the minimum height
		resizeDifference.height = minimumHeight - ownSize.height;
	}
	else
	{
		if(calculatedWidth < availableWidth)
		{
			// the height value takes precedence
			int widthDifference = availableWidth - calculatedWidth;
			resizeDifference.width -= widthDifference;
		}
		else
		{
			// the width value takes precedence
			int heightDifference = availableHeight - calculatedHeight;
			resizeDifference.height -= heightDifference;
		}
	}
	
	return resizeDifference;
}

#pragma mark Overriding NSView Methods

- (void)setFrame:(NSRect)frame
{
	[super setFrame:frame];
	
	[self _layoutContent:frame];
}

#pragma mark Private Methods

- (void)_validateContentViews
{
	BOOL doHideVideoContent = !showVideoContent;
	[videoContentView setHidden:doHideVideoContent];
}

- (void)_layoutContent:(NSRect)frame
{	
	unsigned contentWidth = (unsigned)frame.size.width - LEFT_CONTENT_MARGIN - RIGHT_CONTENT_MARGIN;

	NSRect statusContentFrame = [statusContentView frame];
	statusContentFrame.size.width = contentWidth;
	statusContentFrame.origin.y = (unsigned)frame.size.height - TOP_CONTENT_MARGIN - statusContentHeight;
	[statusContentView setFrame:statusContentFrame];
	
	NSRect videoContentFrame;
	unsigned usedHeight = 0;
	if(showVideoContent == YES)
	{
		unsigned videoHeight = (unsigned)XMGetVideoHeightForWidth(contentWidth, XMVideoSize_CIF);
		
		usedHeight += videoHeight + CONTENT_SPACING;
		
		videoContentFrame.size.width = contentWidth;
		videoContentFrame.size.height = videoHeight;
	
		unsigned usedHeight =  BOTTOM_CONTENT_MARGIN + buttonContentHeight + 2*CONTENT_SPACING + videoHeight +
										statusContentHeight + TOP_CONTENT_MARGIN;
		unsigned heightOffset = ((unsigned)frame.size.height - usedHeight) / 2;
		
		videoContentFrame.origin.x = LEFT_CONTENT_MARGIN;
		videoContentFrame.origin.y = BOTTOM_CONTENT_MARGIN + buttonContentHeight + CONTENT_SPACING + heightOffset;
	
		[videoContentView setFrame:videoContentFrame];
	}
}

@end
