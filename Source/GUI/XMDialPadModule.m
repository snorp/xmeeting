/*
 * $Id: XMDialPadModule.m,v 1.8 2006/04/17 17:51:22 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMDialPadModule.h"

#import "XMeeting.h"
#import "XMMainWindowController.h"
#import "XMInstantActionButton.h"

@interface XMDialPadModule (PrivateMethods)

- (void)_startUp:(id)sender;
- (void)_startDown:(id)sender;
- (void)_startLeft:(id)sender;
- (void)_startRight:(id)sender;
- (void)_stop;

@end

@implementation XMDialPadModule

- (id)init
{
	self = [super init];
	
	return self;
}

- (void)dealloc
{	
	[super dealloc];
}

- (void)awakeFromNib
{
	contentViewSize = [contentView frame].size;
	
	[upButton setTarget:self];
	[upButton setBecomesPressedAction:@selector(_startUp:)];
	[upButton setBecomesReleasedAction:@selector(_stop:)];
	[leftButton setTarget:self];
	[leftButton setBecomesPressedAction:@selector(_startLeft:)];
	[leftButton setBecomesReleasedAction:@selector(_stop:)];
	[rightButton setTarget:self];
	[rightButton setBecomesPressedAction:@selector(_startRight:)];
	[rightButton setBecomesReleasedAction:@selector(_stop:)];
	[downButton setTarget:self];
	[downButton setBecomesPressedAction:@selector(_startDown:)];
	[downButton setBecomesReleasedAction:@selector(_stop:)];
}

- (NSString *)name
{
	return @"Remote Control";
}

- (NSImage *)image
{
	return nil;
}

- (NSView *)contentView
{
	if(contentView == nil)
	{
		[NSBundle loadNibNamed:@"DialPadModule" owner:self];
	}
	
	return contentView;
}

- (NSSize)contentViewSize
{
	// if not already done, causing the nib file to load
	[self contentView];
	
	return contentViewSize;
}

- (void)becomeActiveModule
{
}

- (void)becomeInactiveModule
{
}

#pragma mark -
#pragma mark Action Methods

- (IBAction)userInputToneButtonPressed:(id)sender
{
	char tone = 0;

	if(sender == button0)
	{
		tone = '0';
	}
	else if(sender == button1)
	{
		tone = '1';
	}
	else if(sender == button2)
	{
		tone = '2';
	}
	else if(sender == button3)
	{
		tone = '3';
	}
	else if(sender == button4)
	{
		tone = '4';
	}
	else if(sender == button5)
	{
		tone = '5';
	} 
	else if(sender == button6)
	{
		tone = '6';
	}
	else if(sender == button7)
	{
		tone = '7';
	}
	else if(sender == button8)
	{
		tone = '8';
	}
	else if(sender == button9)
	{
		tone = '9';
	}
	else if(sender == button10)
	{
		tone = '*';
	}
	else if(sender == button11)
	{
		tone = '#';
	}
	else
	{
		return;
	}
	
	
	XMCallManager *callManager = [XMCallManager sharedInstance];
	
	if([callManager isInCall])
	{
		[callManager sendUserInputTone:tone];
	}
}

- (void)_startUp:(id)sender
{
	NSLog(@"startUP");
	XMCallManager *callManager = [XMCallManager sharedInstance];
	
	if([callManager isInCall])
	{
		[callManager startCameraEvent:XMCameraEvent_TiltUp];
	}
}

- (void)_startDown:(id)sender
{
	NSLog(@"startDown");
	XMCallManager *callManager = [XMCallManager sharedInstance];
	
	if([callManager isInCall])
	{
		[callManager startCameraEvent:XMCameraEvent_TiltDown];
	}
}

- (void)_startLeft:(id)sender
{
	NSLog(@"startLeft");
	XMCallManager *callManager = [XMCallManager sharedInstance];
	
	if([callManager isInCall])
	{
		[callManager startCameraEvent:XMCameraEvent_PanLeft];
	}
}

- (void)_startRight:(id)sender
{
	NSLog(@"startRight");
	XMCallManager *callManager = [XMCallManager sharedInstance];
	
	if([callManager isInCall])
	{
		[callManager startCameraEvent:XMCameraEvent_PanRight];
	}
}

- (void)_stop:(id)sender
{
	NSLog(@"STOP");
	XMCallManager *callManager = [XMCallManager sharedInstance];
	
	if([callManager isInCall])
	{
		[callManager stopCameraEvent];
	}
}

@end

