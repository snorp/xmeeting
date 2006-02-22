/*
 * $Id: XMInCallOSD.m,v 1.1 2006/02/22 16:12:33 zmit Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Ivan Guajana. All rights reserved.
 */

#import "XMInCallOSD.h"


@implementation XMInCallOSD


- (id)initWithFrame:(NSRect)frameRect delegate:(id)delegate andSize:(int)size{
	if ((self = [super initWithFrame:frameRect andSize:size]) != nil){
		NSMutableDictionary* fullScreenButton = [super createButtonNamed:@"Fullscreen" 
																tooltips:[NSArray arrayWithObjects:@"Enter fullscreen mode", @"Exit fullscreen mode", nil]
																   icons:[NSArray arrayWithObjects:[NSImage imageNamed:@"fullscreen_large.tif"], [NSImage imageNamed:@"windowed_large.tif"], nil] 
															pressedIcons:[NSArray arrayWithObjects:[NSImage imageNamed:@"fullscreen_large_down.tif"], [NSImage imageNamed:@"windowed_large_down.tif"], nil] 
															   selectors:[NSArray arrayWithObjects:@"goFullScreen", @"goWindowedMode", nil] 
																 targets:[NSArray arrayWithObjects:delegate, delegate, nil] 
													   currentStateIndex:0];
		
		NSMutableDictionary* pinpButton = [super createButtonNamed:@"Picture-in-Picture" 
																tooltips:[NSArray arrayWithObjects:@"Enable Picture-in-Picture", @"Disable Picture-in-Picture", nil]
																   icons:[NSArray arrayWithObjects:[NSImage imageNamed:@"pinp_on_large.tif"], [NSImage imageNamed:@"no_pinp_large.tif"], nil] 
															pressedIcons:[NSArray arrayWithObjects:[NSImage imageNamed:@"pinp_on_large_down.tif"], [NSImage imageNamed:@"no_pinp_large_down.tif"], nil] 
															   selectors:[NSArray arrayWithObjects:@"togglePictureInPicture", @"togglePictureInPicture", nil] 
																 targets:[NSArray arrayWithObjects:delegate, delegate, nil] 
													   currentStateIndex:0];
		
		NSMutableDictionary* pinpModeButton = [super createButtonNamed:@"Picture-in-Picture Mode" 
																tooltips:[NSArray arrayWithObjects:@"Classic Picture-in-Picture", @"3D Picture-in-Picture", @"Side by side Picture-in-Picture", nil]
																   icons:[NSArray arrayWithObjects:[NSImage imageNamed:@"pinpmode_classic_large.tif"], [NSImage imageNamed:@"pinpmode_ichat_large.tif"], [NSImage imageNamed:@"pinpmode_sidebyside_large.tif"], nil] 
															pressedIcons:[NSArray arrayWithObjects:[NSImage imageNamed:@"pinpmode_classic_large_down.tif"], [NSImage imageNamed:@"pinpmode_ichat_large_down.tif"], [NSImage imageNamed:@"pinpmode_sidebyside_large_down.tif"],nil] 
															   selectors:[NSArray arrayWithObjects:@"nextPinPModeAnimating:", @"nextPinPModeAnimating:", @"nextPinPModeAnimating:", nil] 
																 targets:[NSArray arrayWithObjects:delegate, delegate, delegate, nil] 
													   currentStateIndex:0];
		
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
		
		[super addButtons:[NSArray arrayWithObjects:fullScreenButton, XM_OSD_Separator, pinpButton, pinpModeButton, XM_OSD_Separator, infoButton, toolsButton, XM_OSD_Separator, muteButton, XM_OSD_Separator, hangupButton, nil]];
	}
	return self;
}

- (void)setPinPState:(BOOL)state{
	if (state)
		[[buttons objectAtIndex:2] setObject:[NSNumber numberWithInt:1] forKey:@"CurrentStateIndex"];
	else
		[[buttons objectAtIndex:2] setObject:[NSNumber numberWithInt:0] forKey:@"CurrentStateIndex"];
}

- (void)setFullscreenState:(BOOL)state{
	if (state)
		[[buttons objectAtIndex:0] setObject:[NSNumber numberWithInt:1] forKey:@"CurrentStateIndex"];
	else
		[[buttons objectAtIndex:0] setObject:[NSNumber numberWithInt:0] forKey:@"CurrentStateIndex"];
}
@end
