/*
 * $Id: XMAudioOnlyOSD.m,v 1.6 2006/06/22 11:36:54 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Ivan Guajana. All rights reserved.
 */

#import "XMAudioOnlyOSD.h"

#import "XMApplicationController.h"
#import "XMOSDVideoView.h"

@interface XMAudioOnlyOSD (PrivateMethods)

- (void)showInspector;
- (void)showTools;
- (void)hangup;
- (void)mute;
- (void)unmute;

@end

@implementation XMAudioOnlyOSD

- (id)initWithFrame:(NSRect)frameRect videoView:(XMOSDVideoView *)theVideoView andSize:(XMOSDSize)size
{
	if ((self = [super initWithFrame:frameRect andSize:size]) != nil)
	{
		videoView = [theVideoView retain];
		
		NSMutableDictionary* infoButton = [super createButtonNamed:@"Info Inspector" 
														  tooltips:[NSArray arrayWithObjects:NSLocalizedString(@"XM_OSD_TOOLTIP_INFO", @""), nil]
															 icons:[NSArray arrayWithObjects:[NSImage imageNamed:@"inspector_bw_large.tif"], nil] 
													  pressedIcons:[NSArray arrayWithObjects:[NSImage imageNamed:@"inspector_bw_large_down.tif"], nil] 
														 selectors:[NSArray arrayWithObjects:@"showInspector", nil] 
														   targets:[NSArray arrayWithObjects:self, nil] 
												 currentStateIndex:0];
		
		NSMutableDictionary* toolsButton = [super createButtonNamed:@"Tools" 
														  tooltips:[NSArray arrayWithObjects:NSLocalizedString(@"XM_OSD_TOOLTIP_TOOLS", @""), nil]
															 icons:[NSArray arrayWithObjects:[NSImage imageNamed:@"tools_large.tif"], nil] 
													  pressedIcons:[NSArray arrayWithObjects:[NSImage imageNamed:@"tools_large_down.tif"], nil] 
														 selectors:[NSArray arrayWithObjects:@"showTools", nil] 
														   targets:[NSArray arrayWithObjects:self, nil] 
												 currentStateIndex:0];
		
		NSMutableDictionary* hangupButton = [super createButtonNamed:@"Hangup" 
															tooltips:[NSArray arrayWithObjects:NSLocalizedString(@"XM_OSD_TOOLTIP_HANGUP", @""), nil]
															   icons:[NSArray arrayWithObjects:[NSImage imageNamed:@"hangup_large.tif"], nil] 
														pressedIcons:[NSArray arrayWithObjects:[NSImage imageNamed:@"hangup_large_down.tif"], nil] 
														   selectors:[NSArray arrayWithObjects:@"hangup", nil] 
															 targets:[NSArray arrayWithObjects:self, nil] 
												   currentStateIndex:0];
		
		NSMutableDictionary* muteButton = [super createButtonNamed:@"Mute/Unmute" 
																tooltips:[NSArray arrayWithObjects:NSLocalizedString(@"XM_OSD_TOOLTIP_MUTE", @""), NSLocalizedString(@"XM_OSD_TOOLTIP_UNMUTE", @""), nil]
																   icons:[NSArray arrayWithObjects:[NSImage imageNamed:@"mute_large.tif"], [NSImage imageNamed:@"unmute_large.tif"], nil] 
															pressedIcons:[NSArray arrayWithObjects:[NSImage imageNamed:@"mute_large_down.tif"], [NSImage imageNamed:@"unmute_large_down.tif"], nil] 
															   selectors:[NSArray arrayWithObjects:@"mute", @"unmute", nil] 
																 targets:[NSArray arrayWithObjects:self, self, nil] 
													   currentStateIndex:0];

		
		[super addButtons:[NSArray arrayWithObjects:infoButton,toolsButton, XM_OSD_Separator, muteButton, XM_OSD_Separator, hangupButton, nil]];
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

- (void)setMutesAudioInput:(BOOL)mutes
{
	int theState;
	
	if(mutes == YES)
	{
		theState = 1;
	}
	else
	{
		theState = 0;
	}
	
	NSNumber *number = [[NSNumber alloc] initWithInt:theState];
	[[buttons objectAtIndex:3] setObject:number forKey:@"CurrentStateIndex"];
	[number release];
	
	[self setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark OSD Action Methods

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
	
	[audioManager setMutesInput:YES];
}

- (void)unmute
{
	XMAudioManager *audioManager = [XMAudioManager sharedInstance];
	
	[audioManager setMutesInput:NO];
}	

@end
