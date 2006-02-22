/*
 * $Id: XMLocalAudioVideoView.m,v 1.2 2006/02/22 16:12:33 zmit Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMLocalAudioVideoView.h"

#define AUDIO_VIDEO_TOP_MARGIN 20
#define AUDIO_VIDEO_BOTTOM_MARGIN 15
#define AUDIO_VIDEO_LEFT_SPACING 20
#define AUDIO_VIDEO_RIGHT_MARGIN 20
#define AUDIO_VIDEO_SPACING 10

@interface XMLocalAudioVideoView (PrivateMethods)

- (void)_layoutContent:(NSRect)frame;

@end

@implementation XMLocalAudioVideoView

#pragma mark Init & Deallocation Methods

- (void)awakeFromNib
{	
	[self addSubview:audioContentView];
	[self addSubview:videoContentView];
	[self setAutoresizesSubviews:NO];

	int audioVideoLeftMargin = [videoContentView frame].size.width + AUDIO_VIDEO_LEFT_SPACING;
	NSRect audioContentFrame = [audioContentView frame];
	audioContentFrame.origin.x = audioVideoLeftMargin;
	[audioContentView setFrame:audioContentFrame];
	
	NSRect videoContentFrame = [videoContentView frame];
	videoContentFrame.origin.x = audioVideoLeftMargin;
	[videoContentView setFrame:videoContentFrame];

	[self _layoutContent:[self frame]];
}

#pragma mark Public Methods

- (NSSize)requiredSize
{
	int width;
	int height;
	
	NSRect audioContentFrame = [audioContentView frame];
	
	width = [videoContentView frame].size.width + 2 * AUDIO_VIDEO_LEFT_SPACING + audioContentFrame.size.width;
	height = AUDIO_VIDEO_BOTTOM_MARGIN;

	NSRect videoContentFrame = [videoContentView frame];
	if (audioContentFrame.size.height > videoContentFrame.size.height){
		height += (int)audioContentFrame.size.height;
	}
	else
	{
		height += (int)videoContentFrame.size.height;
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


- (void)_layoutContent:(NSRect)frame
{
	
	NSRect audioContentFrame = [audioContentView frame];
	NSRect videoContentFrame = [videoContentView frame];
	
	float requiredContentHeight = AUDIO_VIDEO_TOP_MARGIN + audioContentFrame.size.height + AUDIO_VIDEO_BOTTOM_MARGIN;
	
	requiredContentHeight = (requiredContentHeight > videoContentFrame.size.height ? videoContentFrame.size.height : requiredContentHeight);
		
	videoContentFrame.origin.y = AUDIO_VIDEO_BOTTOM_MARGIN;
	videoContentFrame.origin.x = AUDIO_VIDEO_LEFT_SPACING;
	[videoContentView setFrame:videoContentFrame];
	
	audioContentFrame.origin.y = videoContentFrame.origin.y + (videoContentFrame.size.height - audioContentFrame.size.height);
	audioContentFrame.origin.x = videoContentFrame.origin.x + videoContentFrame.size.width + AUDIO_VIDEO_LEFT_SPACING;
	[audioContentView setFrame:audioContentFrame];


}

@end
