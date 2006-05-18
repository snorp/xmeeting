/*
 * $Id: XMInfoModule.m,v 1.11 2006/05/18 20:41:58 hfriederich Exp $
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
	return @"Status";
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
		[ipAddressSemaphoreView setImage:[NSImage imageNamed:@"semaphore_red"]];
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
	[ipAddressSemaphoreView setImage:[NSImage imageNamed:@"semaphore_green"]];
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
			[h323StatusSemaphoreView setImage:[NSImage imageNamed:@"semaphore_green"]];
			
			unsigned h323AccountTag = [activeLocation h323AccountTag];
			if(h323AccountTag != 0)
			{
				NSString *gatekeeper = [callManager gatekeeperName];
				XMH323Account *h323Account = [preferencesManager h323AccountWithTag:h323AccountTag];
				NSString *phoneNumber = [h323Account phoneNumber];
				
				if(phoneNumber == nil)
				{
					phoneNumber = @"";
				}
				[phoneNumberField setStringValue:phoneNumber];
				
				if(gatekeeper != nil)
				{
					[gatekeeperField setStringValue:gatekeeper];
					[gatekeeperSemaphoreView setImage:[NSImage imageNamed:@"semaphore_green"]];
					[phoneNumberField setTextColor:[NSColor controlTextColor]];
				}
				else
				{
					[gatekeeperField setStringValue:@"Failed to register"];
					[gatekeeperSemaphoreView setImage:[NSImage imageNamed:@"semaphore_red"]];
					[phoneNumberField setTextColor:[NSColor disabledControlTextColor]];
				}
			}
			else
			{
				[gatekeeperField setStringValue:@"Not Used"];
				[gatekeeperSemaphoreView setImage:nil];
				[phoneNumberField setStringValue:@""];
			}
		}
		else
		{
			[h323StatusField setStringValue:@"Failed to enable"];
			[h323StatusSemaphoreView setImage:[NSImage imageNamed:@"semaphore_red"]];
			[gatekeeperField setStringValue:@""];
			[gatekeeperSemaphoreView setImage:nil];
			[phoneNumberField setStringValue:@""];
		}
	}
	else
	{
		[h323StatusField setStringValue:@"Not Enabled"];
		[h323StatusSemaphoreView setImage:nil];
		[gatekeeperField setStringValue:@""];
		[gatekeeperSemaphoreView setImage:nil];
		[phoneNumberField setStringValue:@""];
	}
	
	// setting up the SIP info
	if([activeLocation enableSIP] == YES)
	{
		if([callManager isSIPListening] == YES)
		{
			[sipStatusField setStringValue:@"Online"];
			[sipStatusSemaphoreView setImage:[NSImage imageNamed:@"semaphore_green"]];
			
			unsigned sipAccountTag = [activeLocation sipAccountTag];
			if(sipAccountTag != 0)
			{
				NSString *registrar = nil;
				unsigned registrarCount = [callManager registrarCount];
				if(registrarCount != 0)
				{
					registrar = [callManager registrarHostAtIndex:0];
				}
				
				if(registrar != nil)
				{
					XMSIPAccount *sipAccount = [preferencesManager sipAccountWithTag:sipAccountTag];
					NSString *username = [sipAccount username];
					
					if(username == nil)
					{
						username = @"";
					}
					
					[registrarField setStringValue:registrar];
					[registrarSemaphoreView setImage:[NSImage imageNamed:@"semaphore_green"]];
					[sipUsernameField setStringValue:username];
				}
				else
				{
					[registrarField setStringValue:@"Failed to register"];
					[registrarSemaphoreView setImage:[NSImage imageNamed:@"semaphore_red"]];
					[sipUsernameField setStringValue:@""];
				}
			}
			else
			{
				[registrarField setStringValue:@"Not Used"];
				[registrarSemaphoreView setImage:nil];
				[sipUsernameField setStringValue:@""];
			}
		}
		else
		{
			[sipStatusField setStringValue:@"Failed to enable"];
			[sipStatusSemaphoreView setImage:[NSImage imageNamed:@"semaphore_red"]];
			[registrarField setStringValue:@""];
			[registrarSemaphoreView setImage:nil];
			[sipUsernameField setStringValue:@""];
		}
	}
	else
	{
		[sipStatusField setStringValue:@"Not Enabled"];
		[sipStatusSemaphoreView setImage:nil];
		[registrarField setStringValue:@""];
		[registrarSemaphoreView setImage:nil];
		[sipUsernameField setStringValue:@""];
	}
}

@end
