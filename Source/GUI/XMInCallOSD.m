/*
 * $Id: XMInCallOSD.m,v 1.2 2006/03/23 10:04:48 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Ivan Guajana. All rights reserved.
 */

#import "XMInCallOSD.h"

#import "XMeeting.h"
#import "XMApplicationController.h"
#import "XMOSDVideoView.h"

@interface XMInCallOSD (PrivateMethods)

- (void)_setNextPinPMode;

@end

@implementation XMInCallOSD

- (id)initWithFrame:(NSRect)frameRect videoView:(XMOSDVideoView *)theVideoView andSize:(XMOSDSize)size
{
	if ((self = [super initWithFrame:frameRect andSize:size]) != nil)
	{
		videoView = [theVideoView retain];
		
		NSMutableDictionary* fullScreenButton = [super createButtonNamed:@"Fullscreen" 
																tooltips:[NSArray arrayWithObjects:@"Enter fullscreen mode", @"Exit fullscreen mode", nil]
																   icons:[NSArray arrayWithObjects:[NSImage imageNamed:@"fullscreen_large.tif"], [NSImage imageNamed:@"windowed_large.tif"], nil] 
															pressedIcons:[NSArray arrayWithObjects:[NSImage imageNamed:@"fullscreen_large_down.tif"], [NSImage imageNamed:@"windowed_large_down.tif"], nil] 
															   selectors:[NSArray arrayWithObjects:@"beginFullScreen", @"endFullScreen", nil] 
																 targets:[NSArray arrayWithObjects:self, self, nil] 
													   currentStateIndex:0];
		
		NSMutableDictionary* pinpButton = [super createButtonNamed:@"Picture-in-Picture" 
																tooltips:[NSArray arrayWithObjects:@"Enable Picture-in-Picture", @"Disable Picture-in-Picture", nil]
																   icons:[NSArray arrayWithObjects:[NSImage imageNamed:@"pinp_on_large.tif"], [NSImage imageNamed:@"no_pinp_large.tif"], nil] 
															pressedIcons:[NSArray arrayWithObjects:[NSImage imageNamed:@"pinp_on_large_down.tif"], [NSImage imageNamed:@"no_pinp_large_down.tif"], nil] 
															   selectors:[NSArray arrayWithObjects:@"enablePinP", @"disablePinP", nil] 
																 targets:[NSArray arrayWithObjects:self, self, nil] 
													   currentStateIndex:0];
		
		NSMutableDictionary* pinpModeButton = [super createButtonNamed:@"Picture-in-Picture Mode" 
																tooltips:[NSArray arrayWithObjects:@"Show classic Picture-in-Picture", @"Show 3D Picture-in-Picture", @"Show side by side Picture-in-Picture", nil]
																   icons:[NSArray arrayWithObjects:[NSImage imageNamed:@"pinpmode_classic_large.tif"], [NSImage imageNamed:@"pinpmode_ichat_large.tif"], [NSImage imageNamed:@"pinpmode_sidebyside_large.tif"], nil] 
															pressedIcons:[NSArray arrayWithObjects:[NSImage imageNamed:@"pinpmode_classic_large_down.tif"], [NSImage imageNamed:@"pinpmode_ichat_large_down.tif"], [NSImage imageNamed:@"pinpmode_sidebyside_large_down.tif"],nil] 
															   selectors:[NSArray arrayWithObjects:@"showNextPinPMode", @"showNextPinPMode", @"showNextPinPMode", nil] 
																 targets:[NSArray arrayWithObjects:self, self, self, nil] 
													   currentStateIndex:0];
		
		NSMutableDictionary* infoButton = [super createButtonNamed:@"Info Inspector" 
																tooltips:[NSArray arrayWithObjects:@"Show Info Inspector", nil]
																   icons:[NSArray arrayWithObjects:[NSImage imageNamed:@"inspector_bw_large.tif"], nil] 
															pressedIcons:[NSArray arrayWithObjects:[NSImage imageNamed:@"inspector_bw_large_down.tif"], nil] 
															   selectors:[NSArray arrayWithObjects:@"showInspector", nil] 
																 targets:[NSArray arrayWithObjects:self, nil] 
													   currentStateIndex:0];
		
		NSMutableDictionary* toolsButton = [super createButtonNamed:@"Tools" 
														   tooltips:[NSArray arrayWithObjects:@"Show Tools", nil]
															  icons:[NSArray arrayWithObjects:[NSImage imageNamed:@"tools_large.tif"], nil] 
													   pressedIcons:[NSArray arrayWithObjects:[NSImage imageNamed:@"tools_large_down.tif"], nil] 
														  selectors:[NSArray arrayWithObjects:@"showTools", nil] 
															targets:[NSArray arrayWithObjects:self, nil] 
												  currentStateIndex:0];

		NSMutableDictionary* hangupButton = [super createButtonNamed:@"Hangup" 
														  tooltips:[NSArray arrayWithObjects:@"Terminate call", nil]
															 icons:[NSArray arrayWithObjects:[NSImage imageNamed:@"hangup_large.tif"], nil] 
													  pressedIcons:[NSArray arrayWithObjects:[NSImage imageNamed:@"hangup_large_down.tif"], nil] 
														 selectors:[NSArray arrayWithObjects:@"hangup", nil] 
														   targets:[NSArray arrayWithObjects:self, nil] 
												 currentStateIndex:0];
		
		NSMutableDictionary* muteButton = [super createButtonNamed:@"Mute/Unmute" 
																tooltips:[NSArray arrayWithObjects:@"Mute Microphone", @"Unmute Microphone", nil]
																   icons:[NSArray arrayWithObjects:[NSImage imageNamed:@"mute_large.tif"], [NSImage imageNamed:@"unmute_large.tif"], nil] 
															pressedIcons:[NSArray arrayWithObjects:[NSImage imageNamed:@"mute_large_down.tif"], [NSImage imageNamed:@"unmute_large_down.tif"], nil] 
															   selectors:[NSArray arrayWithObjects:@"mute", @"unmute", nil] 
																 targets:[NSArray arrayWithObjects:self, self, nil] 
													   currentStateIndex:0];
		
		[super addButtons:[NSArray arrayWithObjects:fullScreenButton, XM_OSD_Separator, pinpButton, pinpModeButton, XM_OSD_Separator, infoButton, toolsButton, XM_OSD_Separator, muteButton, XM_OSD_Separator, hangupButton, nil]];
		
		pinpMode = XMPinPMode_SideBySide;
	}
	
	return self;
}

- (void)dealloc
{
	[videoView release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Public Methods

- (void)setPinPMode:(XMPinPMode)mode
{
	int theState;
	int theMode;
	
	if(mode == XMPinPMode_NoPinP)
	{
		theState = 0;
		theMode = 0;
		pinpMode = XMPinPMode_Classic;
	}
	else if(mode == XMPinPMode_Classic)
	{
		theState = 1;
		theMode = 1;
		pinpMode = mode;
	}
	else if(mode == XMPinPMode_3D)
	{
		theState = 1;
		theMode = 2;
		pinpMode = mode;
	}
	else
	{
		theState = 1;
		theMode = 0;
		pinpMode = mode;
	}
	
	NSNumber *number = [[NSNumber alloc] initWithInt:theState];
	[[buttons objectAtIndex:2] setObject:number forKey:@"CurrentStateIndex"];
	[number release];
	
	number = [[NSNumber alloc] initWithInt:theMode];
	[[buttons objectAtIndex:3] setObject:number forKey:@"CurrentStateIndex"];
	[number release];
}

- (void)setIsFullScreen:(BOOL)isFullscreen
{
	if (isFullscreen)
	{
		NSNumber *number = [[NSNumber alloc] initWithInt:1];
		[[buttons objectAtIndex:0] setObject:number forKey:@"CurrentStateIndex"];
		[number release];
	}
	else
	{
		NSNumber *number = [[NSNumber alloc] initWithInt:0];
		[[buttons objectAtIndex:0] setObject:number forKey:@"CurrentStateIndex"];
		[number release];
	}
}

#pragma mark -
#pragma mark OSD Action Methods

- (void)beginFullScreen
{
	[(XMApplicationController *)[NSApp delegate] enterFullScreen:self];
}

- (void)endFullScreen
{
	[(XMApplicationController *)[NSApp delegate] exitFullScreen];
}

- (void)enablePinP
{
	[videoView setPinPMode:pinpMode animate:YES];
}

- (void)disablePinP
{
	[videoView setPinPMode:XMPinPMode_NoPinP animate:YES];
}

- (void)showNextPinPMode
{
	[self _setNextPinPMode];
	[self setPinPMode:pinpMode];
	[videoView setPinPMode:pinpMode animate:YES];
}

- (void)showInspector
{
	XMApplicationController *applicationController = (XMApplicationController *)[NSApp delegate];
	[applicationController showInspector:self];
}

- (void)showTools
{
	XMApplicationController *applicationController = (XMApplicationController *)[NSApp delegate];
	[applicationController showTools:self];
}

- (void)hangup
{
	[[XMCallManager sharedInstance] clearActiveCall];
}

- (void)mute
{	
	XMAudioManager *audioManager = [XMAudioManager sharedInstance];
	
	volume = (unsigned)[audioManager inputVolume];
	
	if([audioManager setInputVolume:0])
	{
	}
}

- (void)unmute
{
	XMAudioManager *audioManager = [XMAudioManager sharedInstance];
	
	if(![audioManager setInputVolume:volume])
	{
	}
}

#pragma mark -
#pragma mark Private Methods

- (void)_setNextPinPMode
{
	if(pinpMode == XMPinPMode_Classic)
	{
		pinpMode = XMPinPMode_3D;
	}
	else if(pinpMode == XMPinPMode_3D)
	{
		pinpMode = XMPinPMode_SideBySide;
	}
	else if(pinpMode == XMPinPMode_SideBySide)
	{
		pinpMode = XMPinPMode_Classic;
	}
}

@end
