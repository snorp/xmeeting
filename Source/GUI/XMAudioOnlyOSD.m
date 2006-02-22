/*
 * $Id: XMAudioOnlyOSD.m,v 1.1 2006/02/22 16:12:33 zmit Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Ivan Guajana. All rights reserved.
 */

#import "XMAudioOnlyOSD.h"


@implementation XMAudioOnlyOSD


- (id)initWithFrame:(NSRect)frameRect delegate:(id)delegate andSize:(int)size{
	if ((self = [super initWithFrame:frameRect andSize:size]) != nil){
		
		NSMutableDictionary* infoButton = [super createButtonNamed:@"Info Inspector" 
														  tooltips:[NSArray arrayWithObjects:@"Show Info Inspector", nil]
															 icons:[NSArray arrayWithObjects:[NSImage imageNamed:@"inspector_bw_large.tif"], nil] 
													  pressedIcons:[NSArray arrayWithObjects:[NSImage imageNamed:@"inspector_bw_large_down.tif"], nil] 
														 selectors:[NSArray arrayWithObjects:@"showInspector", nil] 
														   targets:[NSArray arrayWithObjects:delegate, nil] 
												 currentStateIndex:0];
		
		NSMutableDictionary* toolsButton = [super createButtonNamed:@"Tools" 
														  tooltips:[NSArray arrayWithObjects:@"Show Tools", nil]
															 icons:[NSArray arrayWithObjects:[NSImage imageNamed:@"tools_large.tif"], nil] 
													  pressedIcons:[NSArray arrayWithObjects:[NSImage imageNamed:@"tools_large_down.tif"], nil] 
														 selectors:[NSArray arrayWithObjects:@"showTools", nil] 
														   targets:[NSArray arrayWithObjects:delegate, nil] 
												 currentStateIndex:0];
		
		NSMutableDictionary* hangupButton = [super createButtonNamed:@"Hangup" 
															tooltips:[NSArray arrayWithObjects:@"Terminate current call", nil]
															   icons:[NSArray arrayWithObjects:[NSImage imageNamed:@"hangup_large.tif"], nil] 
														pressedIcons:[NSArray arrayWithObjects:[NSImage imageNamed:@"hangup_large_down.tif"], nil] 
														   selectors:[NSArray arrayWithObjects:@"hangup", nil] 
															 targets:[NSArray arrayWithObjects:delegate, nil] 
												   currentStateIndex:0];
		
		NSMutableDictionary* muteButton = [super createButtonNamed:@"Mute/Unmute" 
																tooltips:[NSArray arrayWithObjects:@"Mute Microphone", @"Unmute Microphone", nil]
																   icons:[NSArray arrayWithObjects:[NSImage imageNamed:@"mute_large.tif"], [NSImage imageNamed:@"unmute_large.tif"], nil] 
															pressedIcons:[NSArray arrayWithObjects:[NSImage imageNamed:@"mute_large_down.tif"], [NSImage imageNamed:@"unmute_large_down.tif"], nil] 
															   selectors:[NSArray arrayWithObjects:@"mute", @"unmute", nil] 
																 targets:[NSArray arrayWithObjects:delegate, delegate, nil] 
													   currentStateIndex:0];

		
		[super addButtons:[NSArray arrayWithObjects:infoButton,toolsButton, XM_OSD_Separator, muteButton, XM_OSD_Separator, hangupButton, nil]];
	}
	return self;
}
@end
