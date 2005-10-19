/*
 * $Id: XMLocalAudioVideoView.m,v 1.1 2005/10/19 22:09:17 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMLocalAudioVideoView.h"

#define AUDIO_VIDEO_TOP_MARGIN 20
#define AUDIO_VIDEO_BOTTOM_MARGIN 10
#define AUDIO_VIDEO_LEFT_SPACING 2
#define AUDIO_VIDEO_RIGHT_MARGIN 20
#define AUDIO_VIDEO_SPACING 10
#define DISCLOSURE_CONTENT_SPACING 2

@interface XMLocalAudioVideoView (PrivateMethods)

- (void)_validateContentVisibility;
- (void)_layoutContent:(NSRect)frame;

@end

@implementation XMLocalAudioVideoView

#pragma mark Init & Deallocation Methods

- (void)awakeFromNib
{	
	[self addSubview:audioContentView];
	[self addSubview:videoContentView];
	[self addSubview:disclosureContentView];
	[self setAutoresizesSubviews:NO];
	
	NSRect disclosureContentFrame = [disclosureContentView frame];
	disclosureContentFrame.origin.x = 0.0;
	disclosureContentFrame.origin.y = DISCLOSURE_CONTENT_SPACING;
	[disclosureContentView setFrame:disclosureContentFrame];
	
	int audioVideoLeftMargin = (int)disclosureContentFrame.size.width + DISCLOSURE_CONTENT_SPACING + AUDIO_VIDEO_LEFT_SPACING;
	NSRect audioContentFrame = [audioContentView frame];
	audioContentFrame.origin.x = audioVideoLeftMargin;
	[audioContentView setFrame:audioContentFrame];
	
	NSRect videoContentFrame = [videoContentView frame];
	videoContentFrame.origin.x = audioVideoLeftMargin;
	[videoContentView setFrame:videoContentFrame];
	
	contentVisible = YES;
	showAudioVideoContent = NO;
	showVideoContent = NO;
	
	[self _validateContentVisibility];
	[self _layoutContent:[self frame]];
}

#pragma mark Public Methods

- (void)setContentVisible:(BOOL)flag
{
	contentVisible = flag;
	
	[self _validateContentVisibility];
	
	[self _layoutContent:[self frame]];
}

- (void)setShowAudioVideoContent:(BOOL)flag
{	
	showAudioVideoContent = flag;
	
	[self _validateContentVisibility];
}

- (void)setShowVideoContent:(BOOL)flag
{
	showVideoContent = flag;
	
	[self _validateContentVisibility];
}

- (NSSize)requiredSize
{
	int width;
	int height;
	
	NSRect disclosureContentFrame = [disclosureContentView frame];
	NSRect audioContentFrame = [audioContentView frame];
	
	if(showAudioVideoContent == NO)
	{
		width = (int)disclosureContentFrame.size.width + DISCLOSURE_CONTENT_SPACING;
		height = (int)disclosureContentFrame.size.height + 2*DISCLOSURE_CONTENT_SPACING;
	}
	else
	{
		width = (int)disclosureContentFrame.size.width + DISCLOSURE_CONTENT_SPACING + AUDIO_VIDEO_LEFT_SPACING +
				(int)audioContentFrame.size.width + AUDIO_VIDEO_RIGHT_MARGIN;
		height = AUDIO_VIDEO_TOP_MARGIN + (int)audioContentFrame.size.height + AUDIO_VIDEO_BOTTOM_MARGIN;
		
		if(showVideoContent == YES)
		{
			NSRect videoContentFrame = [videoContentView frame];
			height += AUDIO_VIDEO_SPACING + (int)videoContentFrame.size.height;
		}
	}
	
	return NSMakeSize(width, height);
}

#pragma mark Overriding NSView methods

- (void)setFrame:(NSRect)frame
{
	[super setFrame:frame];
	
	[self _layoutContent:frame];
}

#pragma mark Private Methods

- (void)_validateContentVisibility
{
	BOOL doHideAudioContent;
	BOOL doHideVideoContent;
	
	doHideAudioContent = (contentVisible == NO || showAudioVideoContent == NO);
	doHideVideoContent = (contentVisible == NO || showAudioVideoContent == NO || showVideoContent == NO);
	
	[audioContentView setHidden:doHideAudioContent];
	[videoContentView setHidden:doHideVideoContent];
}

- (void)_layoutContent:(NSRect)frame
{
	if(contentVisible == NO || showAudioVideoContent == NO)
	{
		return;
	}
	
	NSRect audioContentFrame = [audioContentView frame];
	NSRect videoContentFrame = [videoContentView frame];
	
	float requiredContentHeight = AUDIO_VIDEO_TOP_MARGIN + audioContentFrame.size.height + AUDIO_VIDEO_BOTTOM_MARGIN;
	
	if(showVideoContent == YES)
	{
		requiredContentHeight += AUDIO_VIDEO_SPACING + videoContentFrame.size.height;
	}
	
	int heightOffset = ((int)frame.size.height - requiredContentHeight) / 2;
	
	audioContentFrame.origin.y = AUDIO_VIDEO_BOTTOM_MARGIN + heightOffset;
	[audioContentView setFrame:audioContentFrame];
	
	if(showVideoContent == YES)
	{
		videoContentFrame.origin.y = AUDIO_VIDEO_BOTTOM_MARGIN + heightOffset + (int)audioContentFrame.size.height + AUDIO_VIDEO_SPACING;
		[videoContentView setFrame:videoContentFrame];
	}
}

@end
