/*
 * $Id: XMCallHistoryModule.m,v 1.7 2005/10/17 12:57:54 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMCallHistoryModule.h"

#import "XMeeting.h"
#import "XMCallAddressManager.h"
#import "XMMainWindowController.h"
#import "XMPreferencesManager.h"
#import "XMLocation.h"
#import "XMRecentCallsView.h"
#import "XMApplicationFunctions.h"

@interface XMCallHistoryModule (PrivateMethods)

- (void)_activeLocationDidChange:(NSNotification *)notif;
- (void)_didStartCallInitiation:(NSNotification *)notif;
- (void)_didStartCalling:(NSNotification *)notif;
- (void)_didNotStartCalling:(NSNotification *)notif;
- (void)_didReceiveIncomingCall:(NSNotification *)notif;
- (void)_didEstablishCall:(NSNotification *)notif;
- (void)_didClearCall:(NSNotification *)notif;
- (void)_didNotEnableH323:(NSNotification *)notif;
- (void)_didRegisterAtGatekeeper:(NSNotification *)notif;
- (void)_didUnregisterFromGatekeeper:(NSNotification *)notif;
- (void)_didNotRegisterAtGatekeeper:(NSNotification *)notif;

- (void)_didOpenOutgoingAudioStream:(NSNotification *)notif;
- (void)_didOpenIncomingAudioStream:(NSNotification *)notif;
- (void)_didOpenOutgoingVideoStream:(NSNotification *)notif;
- (void)_didOpenIncomingVideoStream:(NSNotification *)notif;
- (void)_didCloseOutgoingAudioStream:(NSNotification *)notif;
- (void)_didCloseIncomingAudioStream:(NSNotification *)notif;
- (void)_didCloseOutgoingVideoStream:(NSNotification *)notif;
- (void)_didCloseIncomingVideoStream:(NSNotification *)notif;

- (void)_logText:(NSString *)text date:(NSDate *)date;

@end

@implementation XMCallHistoryModule

- (id)init
{
	[[XMMainWindowController sharedInstance] addAdditionModule:self];
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter addObserver:self selector:@selector(_activeLocationDidChange:)
							   name:XMNotification_ActiveLocationDidChange object:nil];
	
	[notificationCenter addObserver:self selector:@selector(_didStartCallInitiation:)
							   name:XMNotification_CallManagerDidStartCallInitiation object:nil];
	[notificationCenter addObserver:self selector:@selector(_didStartCalling:)
							   name:XMNotification_CallManagerDidStartCalling object:nil];
	[notificationCenter addObserver:self selector:@selector(_didNotStartCalling:)
							   name:XMNotification_CallManagerDidNotStartCalling object:nil];
	[notificationCenter addObserver:self selector:@selector(_didReceiveIncomingCall:)
							   name:XMNotification_CallManagerDidReceiveIncomingCall object:nil];
	[notificationCenter addObserver:self selector:@selector(_didEstablishCall:)
							   name:XMNotification_CallManagerDidEstablishCall object:nil];
	[notificationCenter addObserver:self selector:@selector(_didClearCall:)
							   name:XMNotification_CallManagerDidClearCall object:nil];
	[notificationCenter addObserver:self selector:@selector(_didNotEnableH323:)
							   name:XMNotification_CallManagerDidNotEnableH323 object:nil];
	[notificationCenter addObserver:self selector:@selector(_didRegisterAtGatekeeper:)
							   name:XMNotification_CallManagerDidRegisterAtGatekeeper object:nil];
	[notificationCenter addObserver:self selector:@selector(_didUnregisterFromGatekeeper:)
							   name:XMNotification_CallManagerDidUnregisterFromGatekeeper object:nil];
	[notificationCenter addObserver:self selector:@selector(_didNotRegisterAtGatekeeper:)
							   name:XMNotification_CallManagerDidNotRegisterAtGatekeeper object:nil];
	
	[notificationCenter addObserver:self selector:@selector(_didOpenOutgoingAudioStream:)
							   name:XMNotification_CallManagerDidOpenOutgoingAudioStream object:nil];
	[notificationCenter addObserver:self selector:@selector(_didOpenIncomingAudioStream:)
							   name:XMNotification_CallManagerDidOpenIncomingAudioStream object:nil];
	[notificationCenter addObserver:self selector:@selector(_didOpenOutgoingVideoStream:)
							   name:XMNotification_CallManagerDidOpenOutgoingVideoStream object:nil];
	[notificationCenter addObserver:self selector:@selector(_didOpenIncomingVideoStream:)
							   name:XMNotification_CallManagerDidOpenIncomingVideoStream object:nil];
	[notificationCenter addObserver:self selector:@selector(_didCloseOutgoingAudioStream:)
							   name:XMNotification_CallManagerDidCloseOutgoingAudioStream object:nil];
	[notificationCenter addObserver:self selector:@selector(_didCloseIncomingAudioStream:)
							   name:XMNotification_CallManagerDidCloseIncomingAudioStream object:nil];
	[notificationCenter addObserver:self selector:@selector(_didCloseOutgoingVideoStream:)
							   name:XMNotification_CallManagerDidCloseOutgoingVideoStream object:nil];
	[notificationCenter addObserver:self selector:@selector(_didCloseIncomingVideoStream:)
							   name:XMNotification_CallManagerDidCloseIncomingVideoStream object:nil];
	
	nibLoader = nil;
	
	didLogIncomingCall = NO;
	
	gatekeeperName = nil;
	callAddress = nil;
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	if(nibLoader != nil)
	{
		[nibLoader release];
	}
	
	if(gatekeeperName != nil)
	{
		[gatekeeperName release];
	}
	
	if(callAddress != nil)
	{
		[callAddress release];
	}
	
	[super dealloc];
}

- (void)awakeFromNib
{
	contentViewSize = [contentView frame].size;

	[recentCallsScrollView setBorderType:NSBezelBorder];
	[recentCallsScrollView setHasHorizontalScroller:NO];
	[recentCallsScrollView setHasVerticalScroller:YES];
	[[recentCallsScrollView verticalScroller] setControlSize:NSSmallControlSize];
	[recentCallsScrollView setAutohidesScrollers:NO];
	NSSize contentSize = [recentCallsScrollView contentSize];
	[recentCallsView setFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)];
	[recentCallsScrollView setDocumentView:recentCallsView];
}

- (NSString *)name
{
	return @"Call History";
}

- (NSImage *)image
{
	return [NSImage imageNamed:@"CallHistory"];
}

- (NSView *)contentView
{
	if(nibLoader == nil)
	{
		nibLoader = [[NSNib alloc] initWithNibNamed:@"CallHistoryModule" bundle:nil];
		[nibLoader instantiateNibWithOwner:self topLevelObjects:nil];
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

#pragma mark Private Methods

- (void)_activeLocationDidChange:(NSNotification *)notif
{
	XMLocation *activeLocation = [[XMPreferencesManager sharedInstance] activeLocation];
	NSString *logText = [[NSString alloc] initWithFormat:@"Switched active location to <%@>", [activeLocation name]];
	
	[self _logText:logText date:nil];
	
	[logText release];
}

- (void)_didStartCallInitiation:(NSNotification *)notif
{
	if(callAddress != nil)
	{
		[callAddress release];
		callAddress = nil;
	}
	
	callAddress = [[XMCallAddressManager sharedInstance] activeCallAddress];
}

- (void)_didStartCalling:(NSNotification *)notif
{
	XMCallInfo *activeCall = [[XMCallManager sharedInstance] activeCall];
	NSString *logText = [[NSString alloc] initWithFormat:@"Calling host \"%@\"", [activeCall callAddress]];
	
	[self _logText:logText date:[activeCall callInitiationDate]];
	
	[logText release];
	
	[callAddress release];
	callAddress = nil;
}

- (void)_didNotStartCalling:(NSNotification *)notif
{
	NSString *logText = [[NSString alloc] initWithFormat:@"Calling host \"%@\" failed", [[callAddress url] address]];
	
	[self _logText:logText date:nil];
	
	[logText release];
	
	[callAddress release];
	callAddress = nil;
}

- (void)_didReceiveIncomingCall:(NSNotification *)notif
{
	XMCallInfo *activeCall = [[XMCallManager sharedInstance] activeCall];
	NSString *logText = [[NSString alloc] initWithFormat:@"Incoming call from \"%@\"", [activeCall remoteName]];
	
	[self _logText:logText date:[activeCall callInitiationDate]];
	
	[logText release];
	
	didLogIncomingCall = YES;
}
	
- (void)_didEstablishCall:(NSNotification *)notif
{
	XMCallInfo *activeCall = [[XMCallManager sharedInstance] activeCall];
	
	if([activeCall isOutgoingCall] == NO && didLogIncomingCall == NO)
	{
		[self _didReceiveIncomingCall:notif];
	}
	
	NSString *logText = [[NSString alloc] initWithFormat:@"Call with \"%@\" established", [activeCall remoteName]];
	
	[self _logText:logText date:[activeCall callStartDate]];
	
	[logText release];
	
	didLogIncomingCall = NO;
}

- (void)_didClearCall:(NSNotification *)notif
{
	XMCallInfo *activeCall = (XMCallInfo *)[[[XMCallManager sharedInstance] recentCalls] objectAtIndex:0];
	
	NSString *remoteName = [activeCall remoteName];
	
	if(remoteName == nil)
	{
		remoteName = [activeCall callAddress];
		
		if(remoteName == nil)
		{
			remoteName = @"<Unknown>";
		}
	}
	
	NSString *logText = [[NSString alloc] initWithFormat:@"Call with \"%@\" cleared", remoteName];
	
	[self _logText:logText date:[activeCall callEndDate]];
	
	[logText release];
	
	didLogIncomingCall = NO;
}

- (void)_didNotEnableH323:(NSNotification *)notif
{
	[self _logText:@"Enabling the H.323 subsystem failed." date:nil];
}

- (void)_didRegisterAtGatekeeper:(NSNotification *)notif
{
	if(gatekeeperName != nil)
	{
		[gatekeeperName release];
		gatekeeperName = nil;
	}
	
	gatekeeperName = [[[XMCallManager sharedInstance] gatekeeperName] retain];
	
	NSString *logText = [[NSString alloc] initWithFormat:@"Registered at gatekeeper \"%@\"", gatekeeperName];
	
	[self _logText:logText date:nil];
	
	[logText release];
}

- (void)_didUnregisterFromGatekeeper:(NSNotification *)notif
{	
	NSString *logText = [[NSString alloc] initWithFormat:@"Unregistered from gatekeeper \"%@\"", gatekeeperName];
	
	[self _logText:logText date:nil];
	
	[logText release];
}

- (void)_didNotRegisterAtGatekeeper:(NSNotification *)notif
{
	XMLocation *activeLocation = [[XMPreferencesManager sharedInstance] activeLocation];
	
	NSString *gatekeeperAddress = [activeLocation gatekeeperAddress];
	if(gatekeeperAddress == nil)
	{
		gatekeeperAddress = [activeLocation gatekeeperID];
		
		if(gatekeeperAddress == nil)
		{
			gatekeeperAddress = @"<None>";
		}
	}
	
	XMGatekeeperRegistrationFailReason failReason = [[XMCallManager sharedInstance] gatekeeperRegistrationFailReason];
	NSString *failReasonString = gatekeeperRegistrationFailReasonString(failReason);
	
	NSString *logText = [[NSString alloc] initWithFormat:@"Failed to register at gatekeeper \"%@\" (%@)",
		gatekeeperAddress, failReasonString];
	
	[self _logText:logText date:nil];
	
	[logText release];
}

- (void)_didOpenOutgoingAudioStream:(NSNotification *)notif
{
	NSString *codec = [[[XMCallManager sharedInstance] activeCall] outgoingAudioCodec];
	NSString *logText = [[NSString alloc] initWithFormat:@"Media stream opened: sending \"%@\"", codec];
	
	[self _logText:logText date:nil];
	
	[logText release];
}

- (void)_didOpenIncomingAudioStream:(NSNotification *)notif
{
	NSString *codec = [[[XMCallManager sharedInstance] activeCall] incomingAudioCodec];
	NSString *logText = [[NSString alloc] initWithFormat:@"Media stream opened: receiving \"%@\"", codec];
	
	[self _logText:logText date:nil];
	
	[logText release];
}

- (void)_didOpenOutgoingVideoStream:(NSNotification *)notif
{
	NSString *codec = [[[XMCallManager sharedInstance] activeCall] outgoingVideoCodec];
	NSString *logText = [[NSString alloc] initWithFormat:@"Media stream opened: sending \"%@\"", codec];
	
	[self _logText:logText date:nil];
	
	[logText release];
}

- (void)_didOpenIncomingVideoStream:(NSNotification *)notif
{
	NSString *codec = [[[XMCallManager sharedInstance] activeCall] incomingVideoCodec];
	NSString *logText = [[NSString alloc] initWithFormat:@"Media stream opened: receiving \"%@\"", codec];
	
	[self _logText:logText date:nil];
	
	[logText release];
}

- (void)_didCloseOutgoingAudioStream:(NSNotification *)notif
{
	NSString *codec = [[[XMCallManager sharedInstance] activeCall] outgoingAudioCodec];
	NSString *logText = [[NSString alloc] initWithFormat:@"Media stream closed: \"%@\" (Outgoing)", codec];
	
	[self _logText:logText date:nil];
	
	[logText release];
}

- (void)_didCloseIncomingAudioStream:(NSNotification *)notif
{
	NSString *codec = [[[XMCallManager sharedInstance] activeCall] incomingAudioCodec];
	NSString *logText = [[NSString alloc] initWithFormat:@"Media stream closed: \"%@\" (Incoming)", codec];
	
	[self _logText:logText date:nil];
	
	[logText release];
}

- (void)_didCloseOutgoingVideoStream:(NSNotification *)notif
{
	NSString *codec = [[[XMCallManager sharedInstance] activeCall] outgoingVideoCodec];
	NSString *logText = [[NSString alloc] initWithFormat:@"Media stream closed: \"%@\" (Outgoing)", codec];
	
	[self _logText:logText date:nil];
	
	[logText release];
}

- (void)_didCloseIncomingVideoStream:(NSNotification *)notif
{
	NSString *codec = [[[XMCallManager sharedInstance] activeCall] incomingVideoCodec];
	NSString *logText = [[NSString alloc] initWithFormat:@"Media stream closed: \"%@\" (Incoming)", codec];
	
	[self _logText:logText date:nil];
	
	[logText release];
}

- (void)_logText:(NSString *)logText date:(NSDate *)date
{
	BOOL createdDate = NO;
	
	// making sure that the nib file has loaded
	[self contentView];
	
	// fetching the current date
	if(date == nil)
	{
		date = [[NSDate alloc] init];
		createdDate = YES;
	}
	NSString *dateString = [date descriptionWithCalendarFormat:dateFormatString() timeZone:nil locale:nil];
	
	if(createdDate == YES)
	{
		[date release];
	}
	
	// determining the correct (bold) font
	NSFont *boldFont = [NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]];
	
	// setting the correct attributes of the date string
	NSMutableAttributedString *dateLogString = [[NSMutableAttributedString alloc] initWithString:dateString];
	NSRange dateLogRange = NSMakeRange(0, [dateLogString length]);
	[dateLogString beginEditing];
	[dateLogString addAttribute:NSFontAttributeName value:boldFont range:dateLogRange];
	[dateLogString endEditing];
	
	//determining the correct normal font
	NSFont *originalFont = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
	
	// setting the correct attributes of the log string
	NSMutableAttributedString *textLogString = [[NSMutableAttributedString alloc] initWithString:logText];
	NSRange textLogRange = NSMakeRange(0, [textLogString length]);
	[textLogString beginEditing];
	[textLogString addAttribute:NSFontAttributeName value:originalFont range:textLogRange];
	[textLogString endEditing];
	
	// adding the date string to the text storage
	NSTextStorage *logTextStorage = [logTextView textStorage];
	[logTextStorage beginEditing];
	NSMutableString *textStorageMutableString = [logTextStorage mutableString];
	[textStorageMutableString appendString:@"\n"];
	[logTextStorage appendAttributedString:dateLogString];
	[textStorageMutableString appendString:@" "];
	[logTextStorage appendAttributedString:textLogString];
	[logTextStorage endEditing];

	[dateLogString release];
	[textLogString release];
	
	NSRange endRange = NSMakeRange([[logTextView string] length], 0);
	[logTextView scrollRangeToVisible:endRange];
}

@end
