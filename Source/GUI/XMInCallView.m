/*
 * $Id: XMInCallView.m,v 1.3 2005/11/09 20:00:27 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMInCallView.h"

#define TOP_CONTENT_MARGIN 20
#define BOTTOM_CONTENT_MARGIN 20
#define LEFT_CONTENT_MARGIN 20
#define RIGHT_CONTENT_MARGIN 5
#define CONTENT_SPACING 10

@interface XMInCallView (PrivateMethods)

- (void)_validateContentViews;
- (void)_layoutContent:(NSRect)frame;

@end

@implementation XMInCallView

#pragma mark Init & Deallocation Methods

- (void)awakeFromNib
{
	[self addSubview:statusContentView];
	[self addSubview:videoContentView];
	[self addSubview:buttonContentView];
	[self setAutoresizesSubviews:NO];
	
	NSRect statusContentFrame = [statusContentView frame];
	NSRect buttonContentFrame = [buttonContentView frame];
	statusContentHeight = statusContentFrame.size.height;
	buttonContentHeight = buttonContentFrame.size.height;
	minContentWidth = statusContentFrame.size.width;
	
	videoSize = XMVideoSize_CIF;
	
	showVideoContent = NO;
	
	statusContentFrame.origin.x = LEFT_CONTENT_MARGIN;
	[statusContentView setFrame:statusContentFrame];
	
	buttonContentFrame.origin.x = LEFT_CONTENT_MARGIN;
	buttonContentFrame.origin.y = BOTTOM_CONTENT_MARGIN;
	[buttonContentView setFrame:buttonContentFrame];
	
	[self _validateContentViews];
	
	NSRect frame = [self frame];
	frame.size = [self minimumSize];
	[self setFrame:frame];
}

#pragma mark Public Methods

- (void)setShowVideoContent:(BOOL)flag
{
	showVideoContent = flag;
	
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
	height = TOP_CONTENT_MARGIN + statusContentHeight + CONTENT_SPACING + 
					buttonContentHeight + BOTTOM_CONTENT_MARGIN;
	
	if(showVideoContent == YES)
	{
		NSSize theVideoSize = XMGetVideoFrameDimensions(videoSize);
		
		if((unsigned)theVideoSize.width > minContentWidth)
		{
			width = LEFT_CONTENT_MARGIN + (unsigned)theVideoSize.width + RIGHT_CONTENT_MARGIN;
		}
		
		height += (unsigned)theVideoSize.height + CONTENT_SPACING;
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
	
	unsigned videoHeight = XMGetVideoHeightForWidth(contentWidth);
	
	unsigned preferredHeight = BOTTOM_CONTENT_MARGIN + buttonContentHeight + CONTENT_SPACING + videoHeight + CONTENT_SPACING
									+ statusContentHeight + TOP_CONTENT_MARGIN;
	
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
	
	NSSize ownSize = [self frame].size;
	
	unsigned usedHeight = (TOP_CONTENT_MARGIN + statusContentHeight + 2*CONTENT_SPACING + buttonContentHeight + BOTTOM_CONTENT_MARGIN);
	
	int minimumVideoHeight = minimumHeight - usedHeight;
	
	int availableWidth = (int)ownSize.width + (int)resizeDifference.width - LEFT_CONTENT_MARGIN - RIGHT_CONTENT_MARGIN;
	int availableHeight = (int)ownSize.height + (int)resizeDifference.height - usedHeight;
	
	int calculatedWidth = (int)XMGetVideoWidthForHeight(availableHeight);
	int calculatedHeight = (int)XMGetVideoHeightForWidth(availableWidth);
	
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
	// counting away the margins
	unsigned contentWidth = (unsigned)frame.size.width - LEFT_CONTENT_MARGIN - RIGHT_CONTENT_MARGIN;
	
	NSRect buttonContentFrame = [buttonContentView frame];
	unsigned xPos = LEFT_CONTENT_MARGIN + (contentWidth - (int)buttonContentFrame.size.width) / 2;
	buttonContentFrame.origin.x = xPos;
	[buttonContentView setFrame:buttonContentFrame];
	
	NSRect statusContentFrame = [statusContentView frame];
	statusContentFrame.size.width = contentWidth;
	statusContentFrame.origin.y = (unsigned)frame.size.height - TOP_CONTENT_MARGIN - statusContentHeight;
	[statusContentView setFrame:statusContentFrame];
	
	NSRect videoContentFrame;
	unsigned usedHeight = 0;
	if(showVideoContent == YES)
	{
		unsigned videoHeight = (unsigned)XMGetVideoHeightForWidth(contentWidth);
		
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
