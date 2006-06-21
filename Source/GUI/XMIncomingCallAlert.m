/*
 * $Id: XMIncomingCallAlert.m,v 1.1 2006/06/21 22:16:48 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#import "XMIncomingCallAlert.h"

@implementation XMIncomingCallAlert

- (id)initWithCallInfo:(XMCallInfo *)callInfo
{
	self = [super init];
	
	[NSBundle loadNibNamed:@"IncomingCallAlert" owner:self];
	
	NSString *infoTextFormat = NSLocalizedString(@"XM_INCOMING_CALL_INFO_TEXT", @"");
	NSString *detailsTextFormat = NSLocalizedString(@"XM_INCOMING_CALL_DETAILS", @"");
	
	NSString *remoteName = [callInfo remoteName];
	XMCallProtocol callProtocol = [callInfo protocol];
	NSString *callProtocolString;
	if(callProtocol == XMCallProtocol_H323)
	{
		callProtocolString = @"H.323";
	}
	else
	{
		callProtocolString = @"SIP";
	}
	NSString *remoteAddress = [callInfo remoteAddress];
	NSString *remoteNumber = [callInfo remoteNumber];
	NSString *remoteApplication = [callInfo remoteApplication];
	NSString *localAddress = [callInfo localAddress];
	NSString *localAddressInterface = [callInfo localAddressInterface];
	
	if(remoteAddress == nil)
	{
		remoteAddress = @"";
	}
	if(remoteNumber == nil)
	{
		remoteNumber = @"";
	}
	if(remoteApplication == nil)
	{
		remoteApplication = @"";
	}
	if(localAddress == nil)
	{
		localAddress = @"";
	}
	if(localAddressInterface == nil || [localAddressInterface isEqualToString:@"<UNK>"])
	{
		localAddressInterface = NSLocalizedString(@"XM_UNKNOWN", @"");
	}
	else if([localAddressInterface isEqualToString:@"<EXT>"])
	{
		localAddressInterface = NSLocalizedString(@"XM_EXTERNAL_ADDRESS", @"");
	}
	
	NSString *infoText = [[NSString alloc] initWithFormat:infoTextFormat, remoteName];
	[infoField setStringValue:infoText];
	[infoText release];
	
	NSString *detailsText = [[NSString alloc] initWithFormat:detailsTextFormat, callProtocolString, remoteAddress, 
									remoteNumber, remoteApplication, localAddress, localAddressInterface];
	
	[detailsField setStringValue:detailsText];
	[detailsText release];
	
	detailsFieldHeight = [detailsField frame].size.height;
	NSRect frameRect = [panel frame];
	frameRect.size.height -= detailsFieldHeight;
	[panel setFrame:frameRect display:NO];
	
	return self;
}

- (int)runModal
{
	[panel center];
	
	int result = [NSApp runModalForWindow:panel];
	
	[panel orderOut:self];
	
	return result;
}

- (IBAction)acceptCall:(id)sender
{
	[panel orderOut:self];
	
	[NSApp stopModalWithCode:NSAlertFirstButtonReturn];
}

- (IBAction)rejectCall:(id)sender
{
	[panel orderOut:self];
	
	[NSApp stopModalWithCode:NSAlertSecondButtonReturn];
}

- (IBAction)toggleShowDetails:(id)sender
{
	int state = [sender state];
	NSRect frameRect = [panel frame];
	
	if(state == NSOnState)
	{
		frameRect.size.height += detailsFieldHeight;
		frameRect.origin.y -= detailsFieldHeight;
	}
	else
	{
		frameRect.size.height -= detailsFieldHeight;
		frameRect.origin.y += detailsFieldHeight;
	}
	
	[panel setFrame:frameRect display:YES animate:YES];
}

@end
