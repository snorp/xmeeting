/*
 * $Id: XMCallHistoryModule.m,v 1.6 2005/09/01 15:18:23 hfriederich Exp $
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
- (void)_didStartCalling:(NSNotification *)notif;
- (void)_incomingCall:(NSNotification *)notif;
- (void)_callEstablished:(NSNotification *)notif;
- (void)_callCleared:(NSNotification *)notif;
- (void)_enablingH323Failed:(NSNotification *)notif;
- (void)_gatekeeperRegistration:(NSNotification *)notif;
- (void)_gatekeeperUnregistration:(NSNotification *)notif;
- (void)_gatekeeperRegistrationFailed:(NSNotification *)notif;
- (void)_logText:(NSString *)text date:(NSDate *)date;

@end

@implementation XMCallHistoryModule

- (id)init
{
	[[XMMainWindowController sharedInstance] addAdditionModule:self];
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter addObserver:self selector:@selector(_activeLocationDidChange:)
							   name:XMNotification_ActiveLocationDidChange object:nil];
	[notificationCenter addObserver:self selector:@selector(_didStartCalling:)
							   name:XMNotification_CallManagerDidStartCalling object:nil];
	[notificationCenter addObserver:self selector:@selector(_incomingCall:)
							   name:XMNotification_CallManagerIncomingCall object:nil];
	[notificationCenter addObserver:self selector:@selector(_callEstablished:)
							   name:XMNotification_CallManagerCallEstablished object:nil];
	[notificationCenter addObserver:self selector:@selector(_callCleared:)
							   name:XMNotification_CallManagerCallCleared object:nil];
	[notificationCenter addObserver:self selector:@selector(_enablingH323Failed:)
							   name:XMNotification_CallManagerEnablingH323Failed object:nil];
	[notificationCenter addObserver:self selector:@selector(_gatekeeperRegistration:)
							   name:XMNotification_CallManagerGatekeeperRegistration object:nil];
	[notificationCenter addObserver:self selector:@selector(_gatekeeperUnregistration:)
							   name:XMNotification_CallManagerGatekeeperUnregistration object:nil];
	[notificationCenter addObserver:self selector:@selector(_gatekeeperRegistrationFailed:)
							   name:XMNotification_CallManagerGatekeeperRegistrationFailed object:nil];
	
	didLogIncomingCall = NO;
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[nibLoader release];
	
	[gatekeeperName release];
	
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

- (void)_didStartCalling:(NSNotification *)notif
{
	XMCallInfo *activeCall = [[XMCallManager sharedInstance] activeCall];
	NSString *logText = [[NSString alloc] initWithFormat:@"Calling host \"%@\"", [activeCall callAddress]];
	
	[self _logText:logText date:[activeCall callInitiationDate]];
	
	[logText release];
}

- (void)_incomingCall:(NSNotification *)notif
{
	XMCallInfo *activeCall = [[XMCallManager sharedInstance] activeCall];
	NSString *logText = [[NSString alloc] initWithFormat:@"Incoming call from \"%@\"", [activeCall remoteName]];
	
	[self _logText:logText date:[activeCall callInitiationDate]];
	
	[logText release];
	
	didLogIncomingCall = YES;
}
	
- (void)_callEstablished:(NSNotification *)notif
{
	XMCallInfo *activeCall = [[XMCallManager sharedInstance] activeCall];
	
	if([activeCall isOutgoingCall] == NO && didLogIncomingCall == NO)
	{
		[self _incomingCall:notif];
	}
	
	NSString *logText = [[NSString alloc] initWithFormat:@"Call with \"%@\" established", [activeCall remoteName]];
	
	[self _logText:logText date:[activeCall callStartDate]];
	
	[logText release];
	
	didLogIncomingCall = NO;
}

- (void)_callCleared:(NSNotification *)notif
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

- (void)_enablingH323Failed:(NSNotification *)notif
{
	[self _logText:@"Enabling the H.323 subsystem failed!" date:nil];
}

- (void)_gatekeeperRegistration:(NSNotification *)notif
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

- (void)_gatekeeperUnregistration:(NSNotification *)notif
{	
	NSString *logText = [[NSString alloc] initWithFormat:@"Unregistered from gatekeeper \"%@\"", gatekeeperName];
	
	[self _logText:logText date:nil];
	
	[logText release];
}

- (void)_gatekeeperRegistrationFailed:(NSNotification *)notif
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
