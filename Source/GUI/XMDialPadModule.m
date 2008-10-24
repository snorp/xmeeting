/*
 * $Id: XMDialPadModule.m,v 1.16 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#import "XMDialPadModule.h"

#import "XMeeting.h"
#import "XMMainWindowController.h"
#import "XMInstantActionButton.h"

#define XMKey_UserInputMode @"XMeeting_UserInputMode"

@interface XMDialPadModule (PrivateMethods)

- (void)_startUp:(id)sender;
- (void)_startDown:(id)sender;
- (void)_startLeft:(id)sender;
- (void)_startRight:(id)sender;
- (void)_startZoomIn:(id)sender;
- (void)_startZoomOut:(id)sender;
- (void)_stop;

- (void)_didEstablishCall:(NSNotification *)notif;
- (void)_didClearCall:(NSNotification *)notif;
- (void)_didOpenFECCChannel:(NSNotification *)notif;

- (void)_setDialPadButtonsEnabled:(BOOL)flag;
- (void)_setFECCButtonsEnabled:(BOOL)flag;

@end

@implementation XMDialPadModule

- (id)init
{
	self = [super init];
	
	return self;
}

- (void)dealloc
{	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	contentViewSize = [contentView frame].size;
	
	[upButton setTarget:self];
	[upButton setBecomesPressedAction:@selector(_startUp:)];
	[upButton setBecomesReleasedAction:@selector(_stop:)];
	[upButton setKeyCode:NSUpArrowFunctionKey];
	[leftButton setTarget:self];
	[leftButton setBecomesPressedAction:@selector(_startLeft:)];
	[leftButton setBecomesReleasedAction:@selector(_stop:)];
	[leftButton setKeyCode:NSLeftArrowFunctionKey];
	[rightButton setTarget:self];
	[rightButton setBecomesPressedAction:@selector(_startRight:)];
	[rightButton setBecomesReleasedAction:@selector(_stop:)];
	[rightButton setKeyCode:NSRightArrowFunctionKey];
	[downButton setTarget:self];
	[downButton setBecomesPressedAction:@selector(_startDown:)];
	[downButton setBecomesReleasedAction:@selector(_stop:)];
	[downButton setKeyCode:NSDownArrowFunctionKey];
	[zoomInButton setTarget:self];
	[zoomInButton setBecomesPressedAction:@selector(_startZoomIn:)];
	[zoomInButton setBecomesReleasedAction:@selector(_stop:)];
	[zoomOutButton setTarget:self];
	[zoomOutButton setBecomesPressedAction:@selector(_startZoomOut:)];
	[zoomOutButton setBecomesReleasedAction:@selector(_stop:)];
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter addObserver:self selector:@selector(_didEstablishCall:)
							   name:XMNotification_CallManagerDidEstablishCall object:nil];
	[notificationCenter addObserver:self selector:@selector(_didClearCall:)
							   name:XMNotification_CallManagerDidClearCall object:nil];
	[notificationCenter addObserver:self selector:@selector(_didOpenFECCChannel:)
							   name:XMNotification_CallManagerDidOpenFECCChannel object:nil];
	
	XMCallManager *callManager = [XMCallManager sharedInstance];
	
	BOOL enableDialPadButtons = NO;
	if([callManager isInCall])
	{
		enableDialPadButtons = YES;
	}
	BOOL enableFECCButtons = NO;
	if([callManager canSendCameraEvents])
	{
		enableFECCButtons = YES;
	}
	
	[self _setDialPadButtonsEnabled:enableDialPadButtons];
	[self _setFECCButtonsEnabled:enableFECCButtons];
	
	XMUserInputMode inputMode = (XMUserInputMode)[[NSUserDefaults standardUserDefaults] integerForKey:XMKey_UserInputMode];
	[userInputModePopUp selectItemWithTag:inputMode];
	[self userInputModeChanged:nil];
}

#pragma mark -
#pragma mark Module Methods

- (NSString *)identifier
{
	return @"Dial Pad";
}

- (NSString *)name
{
	return NSLocalizedString(@"XM_DIAL_PAD_MODULE_NAME", @"");
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

- (IBAction)userInputModeChanged:(id)sender
{
	XMUserInputMode mode = (XMUserInputMode)[[userInputModePopUp selectedItem] tag];
	[[XMCallManager sharedInstance] setUserInputMode:mode];
	[[NSUserDefaults standardUserDefaults] setInteger:mode forKey:XMKey_UserInputMode];
}

- (void)_startUp:(id)sender
{
	XMCallManager *callManager = [XMCallManager sharedInstance];
	
	if([callManager isInCall])
	{
		[callManager startCameraEvent:XMCameraEvent_TiltUp];
	}
}

- (void)_startDown:(id)sender
{
	XMCallManager *callManager = [XMCallManager sharedInstance];
	
	if([callManager isInCall])
	{
		[callManager startCameraEvent:XMCameraEvent_TiltDown];
	}
}

- (void)_startLeft:(id)sender
{
	XMCallManager *callManager = [XMCallManager sharedInstance];
	
	if([callManager isInCall])
	{
		[callManager startCameraEvent:XMCameraEvent_PanLeft];
	}
}

- (void)_startRight:(id)sender
{
	XMCallManager *callManager = [XMCallManager sharedInstance];
	
	if([callManager isInCall])
	{
		[callManager startCameraEvent:XMCameraEvent_PanRight];
	}
}

- (void)_startZoomIn:(id)sender
{
	XMCallManager *callManager = [XMCallManager sharedInstance];
	
	if([callManager isInCall])
	{
		[callManager startCameraEvent:XMCameraEvent_ZoomIn];
	}
}

- (void)_startZoomOut:(id)sender
{
	XMCallManager *callManager = [XMCallManager sharedInstance];
	
	if([callManager isInCall])
	{
		[callManager startCameraEvent:XMCameraEvent_ZoomOut];
	}
}

- (void)_stop:(id)sender
{
	XMCallManager *callManager = [XMCallManager sharedInstance];
	
	if([callManager isInCall])
	{
		[callManager stopCameraEvent];
	}
}

#pragma mark -
#pragma mark Notification Methods

- (void)_didEstablishCall:(NSNotification *)notif
{
	[self _setDialPadButtonsEnabled:YES];
}

- (void)_didClearCall:(NSNotification *)notif
{
	[self _setDialPadButtonsEnabled:NO];
	[self _setFECCButtonsEnabled:NO];
}

- (void)_didOpenFECCChannel:(NSNotification *)notif
{
	[self _setFECCButtonsEnabled:YES];
}

#pragma mark -
#pragma mark Private Methods

- (void)_setDialPadButtonsEnabled:(BOOL)flag
{
	[button0 setEnabled:flag];
	[button1 setEnabled:flag];
	[button2 setEnabled:flag];
	[button3 setEnabled:flag];
	[button4 setEnabled:flag];
	[button5 setEnabled:flag];
	[button6 setEnabled:flag];
	[button7 setEnabled:flag];
	[button8 setEnabled:flag];
	[button9 setEnabled:flag];
	[button10 setEnabled:flag];
	[button11 setEnabled:flag];
}

- (void)_setFECCButtonsEnabled:(BOOL)flag
{
	[upButton setEnabled:flag];
	[downButton setEnabled:flag];
	[leftButton setEnabled:flag];
	[rightButton setEnabled:flag];
	[zoomInButton setEnabled:flag];
	[zoomOutButton setEnabled:flag];
}

@end

