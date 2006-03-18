/*
 * $Id: XMInfoModule.m,v 1.6 2006/03/18 20:46:22 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Ivan Guajana, Hannes Friederich. All rights reserved.
 */

#import "XMInfoModule.h"

#import "XMeeting.h"
#import "XMPreferencesManager.h"
#import "XMH323Account.h"
#import "XMSIPAccount.h"
#import "XMLocation.h"
#import "XMApplicationFunctions.h"
#import "XMInspectorController.h"

@interface XMInfoModule (PrivateMethods)

- (void)_updateNetworkStatus:(NSNotification *)notif;
- (void)_updateProtocolStatus:(NSNotification *)notif;

@end

@implementation XMInfoModule

#pragma mark Init & Deallocation Methods

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
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter addObserver:self selector:@selector(_updateNetworkStatus:)
							   name:XMNotification_UtilsDidEndFetchingExternalAddress
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_updateNetworkStatus:)
							   name:XMNotification_UtilsDidUpdateLocalAddresses
							 object:nil];
	
	[notificationCenter addObserver:self selector:@selector(_updateProtocolStatus:)
							   name:XMNotification_CallManagerDidEndSubsystemSetup
							 object:nil];

	[self _updateNetworkStatus:nil];
	[self _updateProtocolStatus:nil];
}

#pragma mark -
#pragma mark Protocol Methods

- (NSString *)name
{
	return @"Info";
}

- (NSImage *)image
{
	return [NSImage imageNamed:@"Inspect_small"];
}

- (NSView *)contentView
{
	if(contentView == nil)
	{
		[NSBundle loadNibNamed:@"Info" owner:self];
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
#pragma mark Private Methods

- (void)_displayListeningStatusFieldInformation
{
	/*
	XMCallManager *callManager = [XMCallManager sharedInstance];
	XMUtils *utils = [XMUtils sharedInstance];
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	
	BOOL isH323Listening = [callManager isH323Listening];
	
	if(!isH323Listening)
	{
		[statusFld setStringValue:NSLocalizedString(@"Offline", @"")];
		[ipFld setStringValue:@""];
		[ipFld setStringValue:@""];
		return;
	}

	NSString *externalAddress = [utils externalAddress];
	NSArray *localAddresses = [utils localAddresses];
	unsigned localAddressCount = [localAddresses count];
	
	if(localAddressCount == 0)
	{
		[statusFld setStringValue:NSLocalizedString(@"Offline (No Network Address)", @"")];
		[ipFld setStringValue:@""];
		[ipFld setToolTip:@""];
		return;
	}
	
	[statusFld setStringValue:NSLocalizedString(@"Idle", @"")];
	
	NSMutableString *ipAddressString = [[NSMutableString alloc] initWithCapacity:30];
	unsigned i;
	
	for(i = 0; i < (localAddressCount-1); i++)
	{
		[ipAddressString appendString:[localAddresses objectAtIndex:i]];
		[ipAddressString appendString:@", "];
	}
	[ipAddressString appendString:[localAddresses objectAtIndex:(localAddressCount-1)]];
	
	BOOL useAddressTranslation = [[preferencesManager activeLocation] useAddressTranslation];
	
	if(useAddressTranslation == YES && externalAddress != nil && ![localAddresses containsObject:externalAddress])
	{
		[ipAddressString appendString:@", "];
		[ipAddressString appendString:externalAddress];
		[ipAddressString appendString: @" (External)"];
	}
	
	[ipFld setStringValue:ipAddressString];
	[ipFld setToolTip:ipAddressString];
	[ipAddressString release];
	 */
}

- (void)_gatekeeperRegistrationDidChange:(NSNotification *)notif
{
	/*
	NSString *gatekeeperName = [[XMCallManager sharedInstance] gatekeeperName];
	
	if(gatekeeperName != nil)
	{
		NSString *gatekeeperFormat = NSLocalizedString(@"%@", @"");
		NSString *gatekeeperString = [[NSString alloc] initWithFormat:gatekeeperFormat, gatekeeperName];
		[gkFld setStringValue:gatekeeperString];
		[gatekeeperString release];
		
		[gdsFld setTextColor:[NSColor controlTextColor]];
	}
	else
	{
		[gkFld setStringValue:@""];
		[gdsFld setTextColor:[NSColor disabledControlTextColor]];
	}
	 */
}

/*
- (void)_preferencesDidChange:(NSNotification *)notif
{
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	XMLocation *activeLocation = [preferencesManager activeLocation];
	
	if([activeLocation usesGatekeeper] == YES)
	{
		NSString* phone = [activeLocation gatekeeperPhoneNumber]; 
		[gdsFld setStringValue:phone];
	}
	else
	{
		[gdsFld setStringValue:@""];
	}
}

- (void)_didReceiveIncomingCall:(NSNotification *)notif
{
	[statusFld setStringValue:NSLocalizedString(@"Incoming Call", @"")];
}

- (void)_didStartCalling:(NSNotification *)notif
{
	[statusFld setStringValue:NSLocalizedString(@"In call", @"")];
}*/

- (void)_updateNetworkStatus:(NSNotification *)notif
{
	XMUtils *utils = [XMUtils sharedInstance];
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	
	NSArray *localAddresses = [utils localAddresses];
	NSString *externalAddress = [utils externalAddress];
	unsigned localAddressCount = [localAddresses count];
	
	if(localAddressCount == 0)
	{
		[ipAddressesField setStringValue:@""];
		return;
	}
	
	NSMutableString *ipAddressString = [[NSMutableString alloc] initWithCapacity:30];
	unsigned i;
	
	[ipAddressString appendString:[localAddresses objectAtIndex:0]];
	
	for(i = 1; i < localAddressCount; i++)
	{
		[ipAddressString appendString:@", "];
		[ipAddressString appendString:[localAddresses objectAtIndex:i]];
	}
	
	BOOL useAddressTranslation = [[preferencesManager activeLocation] useAddressTranslation];
	
	if(useAddressTranslation == YES && externalAddress != nil && ![localAddresses containsObject:externalAddress])
	{
		[ipAddressString appendString:@", "];
		[ipAddressString appendString:externalAddress];
		[ipAddressString appendString: @" (External)"];
	}
	
	[ipAddressesField setStringValue:ipAddressString];
	[ipAddressesField setToolTip:ipAddressString];
	[ipAddressString release];
}

- (void)_updateProtocolStatus:(NSNotification *)notif
{
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	XMLocation *activeLocation = [preferencesManager activeLocation];
	XMCallManager *callManager = [XMCallManager sharedInstance];
	
	// setting up the H.323 info
	if([activeLocation enableH323] == YES)
	{
		if([callManager isH323Listening] == YES)
		{
			[h323StatusField setStringValue:@"Online"];
			
			unsigned h323AccountTag = [activeLocation h323AccountTag];
			if(h323AccountTag != 0)
			{
				NSString *gatekeeper = [callManager gatekeeperName];
				XMH323Account *h323Account = [preferencesManager h323AccountWithTag:h323AccountTag];
				NSString *phoneNumber = [h323Account phoneNumber];
				
				[phoneNumberField setStringValue:phoneNumber];
				
				if(gatekeeper != nil)
				{
					[gatekeeperField setStringValue:gatekeeper];
					[phoneNumberField setTextColor:[NSColor controlTextColor]];
				}
				else
				{
					[gatekeeperField setStringValue:@"Failed to register"];
					[phoneNumberField setTextColor:[NSColor disabledControlTextColor]];
				}
			}
			else
			{
				[gatekeeperField setStringValue:@"Not Used"];
				[phoneNumberField setStringValue:@""];
			}
		}
		else
		{
			[h323StatusField setStringValue:@"Failed to enable"];
			[gatekeeperField setStringValue:@""];
			[phoneNumberField setStringValue:@""];
		}
	}
	else
	{
		[h323StatusField setStringValue:@"Not Enabled"];
		[gatekeeperField setStringValue:@""];
		[phoneNumberField setStringValue:@""];
	}
	
	// setting up the SIP info
	if([activeLocation enableSIP] == YES)
	{
		if([callManager isSIPListening] == YES)
		{
			[sipStatusField setStringValue:@"Online"];
			
			unsigned sipAccountTag = [activeLocation sipAccountTag];
			if(sipAccountTag != 0)
			{
				NSString *registrar = nil;
				unsigned registrarCount = [callManager registrarCount];
				if(registrarCount != 0)
				{
					registrar = [callManager registrarNameAtIndex:0];
				}
				
				if(registrar != nil)
				{
					XMSIPAccount *sipAccount = [preferencesManager sipAccountWithTag:sipAccountTag];
					NSString *username = [sipAccount username];
					
					[registrarField setStringValue:registrar];
					[sipUsernameField setStringValue:username];
				}
				else
				{
					[registrarField setStringValue:@"Failed to register"];
					[sipUsernameField setStringValue:@""];
				}
			}
			else
			{
				[registrarField setStringValue:@"Not Used"];
				[sipUsernameField setStringValue:@""];
			}
		}
		else
		{
			[sipStatusField setStringValue:@"Failed to enable"];
			[registrarField setStringValue:@""];
			[sipUsernameField setStringValue:@""];
		}
	}
	else
	{
		[sipStatusField setStringValue:@"Not Enabled"];
		[registrarField setStringValue:@""];
		[sipUsernameField setStringValue:@""];
	}
}

@end
