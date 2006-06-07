/*
 * $Id: XMCallHistoryModule.m,v 1.21 2006/06/07 10:10:15 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMCallHistoryModule.h"

#import "XMeeting.h"
#import "XMPreferencesManager.h"
#import "XMH323Account.h"
#import "XMSIPAccount.h"
#import "XMLocation.h"
#import "XMCallAddressManager.h"
#import "XMMainWindowController.h"
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
- (void)_didNotEnableSIP:(NSNotification *)notif;
- (void)_didRegisterAtSIPRegistrar:(NSNotification *)notif;
- (void)_didUnregisterFromSIPRegistrar:(NSNotification *)notif;
- (void)_didNotRegisterAtSIPRegistrar:(NSNotification *)notif;

- (void)_didOpenOutgoingAudioStream:(NSNotification *)notif;
- (void)_didOpenIncomingAudioStream:(NSNotification *)notif;
- (void)_didOpenOutgoingVideoStream:(NSNotification *)notif;
- (void)_didOpenIncomingVideoStream:(NSNotification *)notif;
- (void)_didCloseOutgoingAudioStream:(NSNotification *)notif;
- (void)_didCloseIncomingAudioStream:(NSNotification *)notif;
- (void)_didCloseOutgoingVideoStream:(NSNotification *)notif;
- (void)_didCloseIncomingVideoStream:(NSNotification *)notif;

- (void)_didChangeVideoInputDevice:(NSNotification *)notif;

- (void)_logText:(NSString *)text date:(NSDate *)date;

@end

@implementation XMCallHistoryModule

- (id)init
{
	self = [super init];
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter addObserver:self selector:@selector(_activeLocationDidChange:)
							   name:XMNotification_PreferencesManagerDidChangeActiveLocation object:nil];
	
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
	[notificationCenter addObserver:self selector:@selector(_didNotEnableSIP:)
							   name:XMNotification_CallManagerDidNotEnableSIP object:nil];
	[notificationCenter addObserver:self selector:@selector(_didRegisterAtSIPRegistrar:)
							   name:XMNotification_CallManagerDidRegisterAtSIPRegistrar object:nil];
	[notificationCenter addObserver:self selector:@selector(_didUnregisterFromSIPRegistrar:)
							   name:XMNotification_CallManagerDidUnregisterFromSIPRegistrar object:nil];
	[notificationCenter addObserver:self selector:@selector(_didNotRegisterAtSIPRegistrar:)
							   name:XMNotification_CallManagerDidNotRegisterAtSIPRegistrar object:nil];
	
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
	
	[notificationCenter addObserver:self selector:@selector(_didChangeVideoInputDevice:)
							   name:XMNotification_VideoManagerDidChangeSelectedInputDevice object:nil];
	
	didLogIncomingCall = NO;
	
	locationName = nil;
	
	gatekeeperName = nil;
	sipRegistrarName = nil;
	
	callAddress = nil;
	
	contentView = nil;
	
	// causing some logs to appear immediately
	[self _activeLocationDidChange:nil];
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	if(locationName != nil)
	{
		[locationName release];
	}
	
	if(gatekeeperName != nil)
	{
		[gatekeeperName release];
	}
	
	if(sipRegistrarName != nil)
	{
		[sipRegistrarName release];
	}
	
	if(videoDevice != nil)
	{
		[videoDevice release];
	}
	
	if(callAddress != nil)
	{
		[callAddress release];
	}
	
	[super dealloc];
}

- (void)awakeFromNib
{
	contentViewMinSize = [contentView frame].size;
	contentViewSize = contentViewMinSize;

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
	return NSLocalizedString(@"XM_CALL_HISTORY_MODULE_NAME", @"");
}

- (NSImage *)image
{
	return [NSImage imageNamed:@"CallHistory"];
}

- (NSView *)contentView
{
	if(contentView == nil)
	{
		[NSBundle loadNibNamed:@"CallHistoryModule" owner:self];
	}
	
	return contentView;
}

- (NSSize)contentViewSize
{
	// if not already done, causing the nib file to load
	[self contentView];
	
	return contentViewSize;
}

- (NSSize)contentViewMinSize
{
	[self contentView];
	
	return contentViewMinSize;
}

- (NSSize)contentViewMaxSize
{
	return NSMakeSize(5000, 5000);
}

- (void)becomeActiveModule
{
}

- (void)becomeInactiveModule
{
	contentViewSize = [contentView frame].size;
}

- (BOOL)isResizableWhenInSeparateWindow
{
	return YES;
}

#pragma mark Private Methods

- (void)_activeLocationDidChange:(NSNotification *)notif
{
	XMLocation *activeLocation = [[XMPreferencesManager sharedInstance] activeLocation];
	
	NSString *activeLocationName = [activeLocation name];
	
	if(![locationName isEqualToString:activeLocationName])
	{
		NSString *logText = [[NSString alloc] initWithFormat:NSLocalizedString(@"XM_CALL_HISTORY_MODULE_LOCATION_SWITCH", @""), activeLocationName];
	
		[self _logText:logText date:nil];
	
		[logText release];
		
		[locationName release];
		locationName = [activeLocationName copy];
	}
}

- (void)_didStartCallInitiation:(NSNotification *)notif
{
	if(callAddress != nil)
	{
		[callAddress release];
		callAddress = nil;
	}
	
	callAddress = [[[XMCallAddressManager sharedInstance] activeCallAddress] retain];
}

- (void)_didStartCalling:(NSNotification *)notif
{
	XMCallInfo *activeCall = [[XMCallManager sharedInstance] activeCall];
	NSString *logText = [[NSString alloc] initWithFormat:NSLocalizedString(@"XM_CALL_HISTORY_MODULE_CALLING", @""), [activeCall callAddress]];
	
	[self _logText:logText date:[activeCall callInitiationDate]];
	
	[logText release];
	
	[callAddress release];
	callAddress = nil;
}

- (void)_didNotStartCalling:(NSNotification *)notif
{
	NSString *logText = [[NSString alloc] initWithFormat:NSLocalizedString(@"XM_CALL_HISTORY_MODULE_CALL_FAILED", @""), [[callAddress addressResource] address]];
	
	[self _logText:logText date:nil];
	
	[logText release];
	
	[callAddress release];
	callAddress = nil;
}

- (void)_didReceiveIncomingCall:(NSNotification *)notif
{
	XMCallInfo *activeCall = [[XMCallManager sharedInstance] activeCall];
	NSString *logText = [[NSString alloc] initWithFormat:NSLocalizedString(@"XM_CALL_HISTORY_MODULE_INCOMING_CALL", @""), [activeCall remoteName]];
	
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
	
	NSString *logText = [[NSString alloc] initWithFormat:NSLocalizedString(@"XM_CALL_HISTORY_MODULE_CALL_ESTABLISHED", @""), [activeCall remoteName]];
	
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
			remoteName = NSLocalizedString(@"XM_UNKNOWN_HOST", @"");
		}
	}
	
	NSString *logText = [[NSString alloc] initWithFormat:NSLocalizedString(@"XM_CALL_HISTORY_MODULE_CALL_CLEARED", @""), remoteName];
	
	[self _logText:logText date:[activeCall callEndDate]];
	
	[logText release];
	
	didLogIncomingCall = NO;
}

- (void)_didNotEnableH323:(NSNotification *)notif
{
	[self _logText:NSLocalizedString(@"XM_CALL_HISTORY_MODULE_H323_FAILURE", @"") date:nil];
}

- (void)_didRegisterAtGatekeeper:(NSNotification *)notif
{
	if(gatekeeperName != nil)
	{
		[gatekeeperName release];
		gatekeeperName = nil;
	}
	
	gatekeeperName = [[[XMCallManager sharedInstance] gatekeeperName] retain];
	
	NSString *logText = [[NSString alloc] initWithFormat:NSLocalizedString(@"XM_CALL_HISTORY_MODULE_GK_REGISTRATION", @""), gatekeeperName];
	
	[self _logText:logText date:nil];
	
	[logText release];
}

- (void)_didUnregisterFromGatekeeper:(NSNotification *)notif
{	
	NSString *logText = [[NSString alloc] initWithFormat:NSLocalizedString(@"XM_CALL_HISTORY_MODULE_GK_UNREGISTRATION", @""), gatekeeperName];
	
	[self _logText:logText date:nil];
	
	[logText release];
}

- (void)_didNotRegisterAtGatekeeper:(NSNotification *)notif
{
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	XMLocation *activeLocation = [preferencesManager activeLocation];
	XMH323Account *h323Account = [preferencesManager h323AccountWithTag:[activeLocation h323AccountTag]];
	
	NSString *gkHost = [h323Account gatekeeper];
	if(gkHost == nil)
	{
		gkHost = NSLocalizedString(@"XM_UNKNOWN_HOST", @"");
	}
	
	XMGatekeeperRegistrationFailReason failReason = [[XMCallManager sharedInstance] gatekeeperRegistrationFailReason];
	NSString *failReasonString = XMGatekeeperRegistrationFailReasonString(failReason);
	
	NSString *logText = [[NSString alloc] initWithFormat:NSLocalizedString(@"XM_CALL_HISTORY_MODULE_GK_REG_FAILURE", @""),
		gkHost, failReasonString];
	
	[self _logText:logText date:nil];
	
	[logText release];
}

- (void)_didNotEnableSIP:(NSNotification *)notif
{
	[self _logText:NSLocalizedString(@"XM_CALL_HISTORY_MODULE_SIP_FAILURE", @"") date:nil];
}

- (void)_didRegisterAtSIPRegistrar:(NSNotification *)notif
{
	if(sipRegistrarName != nil)
	{
		[sipRegistrarName release];
		sipRegistrarName = nil;
	}
	
	sipRegistrarName = [[[XMCallManager sharedInstance] registrarHostAtIndex:0] retain];
	
	NSString *logText = [[NSString alloc] initWithFormat:NSLocalizedString(@"XM_CALL_HISTORY_MODULE_SIP_REGISTRATION", @""), sipRegistrarName];
	
	[self _logText:logText date:nil];
	
	[logText release];
}

- (void)_didUnregisterFromSIPRegistrar:(NSNotification *)notif
{
	NSString *logText = [[NSString alloc] initWithFormat:NSLocalizedString(@"XM_CALL_HISTORY_MODULE_SIP_UNREGISTRATION", @""), sipRegistrarName];
	
	[self _logText:logText date:nil];
	
	[logText release];
}

- (void)_didNotRegisterAtSIPRegistrar:(NSNotification *)notif
{
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	XMLocation *activeLocation = [preferencesManager activeLocation];
	XMSIPAccount *sipAccount = [preferencesManager sipAccountWithTag:[activeLocation sipAccountTag]];
	
	NSString *sipRegistrarHost = [sipAccount registrar];
	if(sipRegistrarHost == nil)
	{
		sipRegistrarHost = NSLocalizedString(@"XM_UNKNOWN_HOST", @"");
	}
	
	XMSIPStatusCode failReason = [[XMCallManager sharedInstance] sipRegistrationFailReasonAtIndex:0];
	NSString *failReasonString = XMSIPStatusCodeString(failReason);
		
	NSString *logText = [[NSString alloc] initWithFormat:NSLocalizedString(@"XM_CALL_HISTORY_MODULE_SIP_REG_FAILURE", @""),
		sipRegistrarHost, failReasonString];
	
	[self _logText:logText date:nil];
	
	[logText release];
}

- (void)_didOpenOutgoingAudioStream:(NSNotification *)notif
{
	NSString *codec = [[[XMCallManager sharedInstance] activeCall] outgoingAudioCodec];
	NSString *logText = [[NSString alloc] initWithFormat:NSLocalizedString(@"XM_CALL_HISTORY_MODULE_OPENED_SENDING", @""), codec];
	
	[self _logText:logText date:nil];
	
	[logText release];
}

- (void)_didOpenIncomingAudioStream:(NSNotification *)notif
{
	NSString *codec = [[[XMCallManager sharedInstance] activeCall] incomingAudioCodec];
	NSString *logText = [[NSString alloc] initWithFormat:NSLocalizedString(@"XM_CALL_HISTORY_MODULE_OPENED_RECEIVING", @""), codec];
	
	[self _logText:logText date:nil];
	
	[logText release];
}

- (void)_didOpenOutgoingVideoStream:(NSNotification *)notif
{
	NSString *codec = [[[XMCallManager sharedInstance] activeCall] outgoingVideoCodec];
	NSString *logText = [[NSString alloc] initWithFormat:NSLocalizedString(@"XM_CALL_HISTORY_MODULE_OPENED_SENDING", @""), codec];
	
	[self _logText:logText date:nil];
	
	[logText release];
}

- (void)_didOpenIncomingVideoStream:(NSNotification *)notif
{
	NSString *codec = [[[XMCallManager sharedInstance] activeCall] incomingVideoCodec];
	NSString *logText = [[NSString alloc] initWithFormat:NSLocalizedString(@"XM_CALL_HISTORY_MODULE_OPENED_RECEIVING", @""), codec];
	
	[self _logText:logText date:nil];
	
	[logText release];
}

- (void)_didCloseOutgoingAudioStream:(NSNotification *)notif
{
	NSString *codec = [[[XMCallManager sharedInstance] activeCall] outgoingAudioCodec];
	NSString *logText = [[NSString alloc] initWithFormat:NSLocalizedString(@"XM_CALL_HISTORY_MODULE_CLOSED_SENDING", @""), codec];
	
	[self _logText:logText date:nil];
	
	[logText release];
}

- (void)_didCloseIncomingAudioStream:(NSNotification *)notif
{
	NSString *codec = [[[XMCallManager sharedInstance] activeCall] incomingAudioCodec];
	NSString *logText = [[NSString alloc] initWithFormat:NSLocalizedString(@"XM_CALL_HISTORY_MODULE_CLOSED_RECEIVING", @""), codec];
	
	[self _logText:logText date:nil];
	
	[logText release];
}

- (void)_didCloseOutgoingVideoStream:(NSNotification *)notif
{
	NSString *codec = [[[XMCallManager sharedInstance] activeCall] outgoingVideoCodec];
	NSString *logText = [[NSString alloc] initWithFormat:NSLocalizedString(@"XM_CALL_HISTORY_MODULE_CLOSED_SENDING", @""), codec];
	
	[self _logText:logText date:nil];
	
	[logText release];
}

- (void)_didCloseIncomingVideoStream:(NSNotification *)notif
{
	NSString *codec = [[[XMCallManager sharedInstance] activeCall] incomingVideoCodec];
	NSString *logText = [[NSString alloc] initWithFormat:NSLocalizedString(@"XM_CALL_HISTORY_MODULE_CLOSED_RECEIVING", @""), codec];
	
	[self _logText:logText date:nil];
	
	[logText release];
}

- (void)_didChangeVideoInputDevice:(NSNotification *)notif
{
	NSString *selectedDevice = [[XMVideoManager sharedInstance] selectedInputDevice];
	
	if(![videoDevice isEqualToString:selectedDevice])
	{
		NSString *logText = [[NSString alloc] initWithFormat:NSLocalizedString(@"XM_CALL_HISTORY_MODULE_VIDEO_DEVICE_SWITCH", @""), selectedDevice];
		
		[self _logText:logText date:nil];
		
		[logText release];
		
		[videoDevice release];
		videoDevice = [selectedDevice copy];
	}
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
	NSString *dateString = [date descriptionWithCalendarFormat:XMDateFormatString() timeZone:nil locale:nil];
	
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
	
	NSString *debugLogMessage = [[NSString alloc] initWithFormat:@"%@ %@", [dateLogString string], [textLogString string]];
	XMLogMessage(debugLogMessage);
	[debugLogMessage release];

	[dateLogString release];
	[textLogString release];
	
	NSRange endRange = NSMakeRange([[logTextView string] length], 0);
	[logTextView scrollRangeToVisible:endRange];
}

@end
