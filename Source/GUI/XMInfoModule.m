/*
 * $Id: XMInfoModule.m,v 1.17 2006/06/28 07:28:50 hfriederich Exp $
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

#define XM_BOTTOM_SPACING 1
#define XM_BOX_X 2
#define XM_BOX_SPACING 13
#define XM_DISCLOSURE_OFFSET -2
#define XM_HIDDEN_OFFSET 4

#define XM_IP_ADDRESSES_TEXT_FIELD_HEIGHT 14

#define XM_SHOW_H323_DETAILS 1
#define XM_SHOW_SIP_DETAILS 2

#define XM_INFO_MODULE_DETAIL_STATUS_KEY @"XMeeting_InfoModuleDetailStatus"

@interface XMInfoModule (PrivateMethods)

- (void)_updateNetworkStatus:(NSNotification *)notif;
- (void)_updateProtocolStatus:(NSNotification *)notif;
- (void)_storeDetailStatus;

@end

@implementation XMInfoModule

#pragma mark Init & Deallocation Methods

- (id)init
{
	self = [super init];
	
	addressExtraHeight = 0;
	h323BoxHeight = 0;
	sipBoxHeight = 0;
	
	showH323Details = NO;
	showSIPDetails = NO;
	
	return self;
}

- (void)dealloc
{	
	[super dealloc];
}

- (void)awakeFromNib
{
	contentViewSize = [contentView frame].size;
	
	h323BoxHeight = [h323Box frame].size.height - XM_HIDDEN_OFFSET;
	sipBoxHeight = [sipBox frame].size.height - XM_HIDDEN_OFFSET;
	float networkBoxHeight = [networkBox frame].size.height;
	float boxWidth = [networkBox frame].size.width;
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter addObserver:self selector:@selector(_updateNetworkStatus:)
							   name:XMNotification_UtilsDidEndFetchingCheckipExternalAddress
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_updateNetworkStatus:)
							   name:XMNotification_UtilsDidUpdateLocalAddresses
							 object:nil];
	[notificationCenter addObserver:self selector:@selector(_updateNetworkStatus:)
							   name:XMNotification_UtilsDidUpdateSTUNInformation
							 object:nil];
	
	[notificationCenter addObserver:self selector:@selector(_updateProtocolStatus:)
							   name:XMNotification_CallManagerDidEndSubsystemSetup
							 object:nil];
	
	unsigned detailStatus = [[NSUserDefaults standardUserDefaults] integerForKey:XM_INFO_MODULE_DETAIL_STATUS_KEY];
	
	if(detailStatus & XM_SHOW_H323_DETAILS)
	{
		showH323Details = YES;
		[h323Disclosure setState:NSOnState];
	}
	else
	{
		showH323Details = NO;
		[h323Disclosure setState:NSOffState];
	}
	
	if(detailStatus & XM_SHOW_SIP_DETAILS)
	{
		showSIPDetails = YES;
		[sipDisclosure setState:NSOnState];
	}
	else
	{
		showSIPDetails = NO;
		[sipDisclosure setState:NSOffState];
	}

	[self _updateNetworkStatus:nil];
	[self _updateProtocolStatus:nil];
	
	// Manually adjusting the frame rects of the contained elements.
	// Otherwise, the resulting GUI does not behave and look as
	// expected, unfortunately
	NSSize size = [self contentViewSize];
	[contentView setFrameSize:size];
	
	NSRect frameRect = NSMakeRect(XM_BOX_X, XM_BOTTOM_SPACING, boxWidth, XM_HIDDEN_OFFSET);
	if(showSIPDetails == YES)
	{
		frameRect.size.height += sipBoxHeight;
	}
	else
	{
		[sipBox setHidden:YES];
	}
	[sipBox setFrame:frameRect];
	
	frameRect.origin.y += frameRect.size.height+XM_DISCLOSURE_OFFSET;
	
	NSRect rect = [sipDisclosure frame];
	rect.origin.y = frameRect.origin.y;
	[sipDisclosure setFrame:rect];
	rect = [sipTitle frame];
	rect.origin.y = frameRect.origin.y;
	[sipTitle setFrame:rect];
	
	frameRect.origin.y -= XM_DISCLOSURE_OFFSET;
	frameRect.origin.y += XM_BOX_SPACING;
	frameRect.size.height = XM_HIDDEN_OFFSET;
	
	if(showH323Details == YES)
	{
		frameRect.size.height += h323BoxHeight;
	}
	else
	{
		[h323Box setHidden:YES];
	}
	[h323Box setFrame:frameRect];
	
	frameRect.origin.y += frameRect.size.height+XM_DISCLOSURE_OFFSET;
	
	rect = [h323Disclosure frame];
	rect.origin.y = frameRect.origin.y;
	[h323Disclosure setFrame:rect];
	rect = [h323Title frame];
	rect.origin.y = frameRect.origin.y;
	[h323Title setFrame:rect];
	
	frameRect.origin.y -= XM_DISCLOSURE_OFFSET;
	frameRect.origin.y += XM_BOX_SPACING;
	frameRect.size.height = networkBoxHeight + addressExtraHeight;
	
	[networkBox setFrame:frameRect];
	
	[ipAddressesField setAutoresizingMask:NSViewHeightSizable];
	rect = [ipAddressesField frame];
	rect.size.height += addressExtraHeight;
	[ipAddressesField setFrame:rect];
}

#pragma mark -
#pragma mark Protocol Methods

- (NSString *)name
{
	return NSLocalizedString(@"XM_INFO_MODULE_NAME", @"");
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
	
	int heightDifference = addressExtraHeight;
	
	if(showH323Details == NO)
	{
		heightDifference -= h323BoxHeight;
	}
	if(showSIPDetails == NO)
	{
		heightDifference -= sipBoxHeight;
	}
	
	return NSMakeSize(contentViewSize.width, contentViewSize.height+heightDifference);
}

- (void)becomeActiveModule
{

}

- (void)becomeInactiveModule
{

}

#pragma mark -
#pragma mark Action Methods

- (IBAction)toggleShowH323Details:(id)sender
{
	showH323Details = !showH323Details;
	
	if(showH323Details == NO)
	{
		[h323Box setHidden:YES];
	}
	
	[networkBox setAutoresizingMask:NSViewMinYMargin];
	
	[h323Box setAutoresizingMask:NSViewHeightSizable];
	[h323Disclosure setAutoresizingMask:NSViewMinYMargin];
	[h323Title setAutoresizingMask:NSViewMinYMargin];
	
	[self resizeContentView];
	
	[networkBox setAutoresizingMask:NSViewHeightSizable];
	
	[h323Box setAutoresizingMask:NSViewMaxYMargin];
	[h323Disclosure setAutoresizingMask:NSViewMaxYMargin];
	[h323Title setAutoresizingMask:NSViewMaxYMargin];
	
	if(showH323Details == YES)
	{
		[h323Box setHidden:NO];
	}
	
	[self _storeDetailStatus];
}

- (IBAction)toggleShowSIPDetails:(id)sender
{
	showSIPDetails = !showSIPDetails;
	
	if(showSIPDetails == NO)
	{
		[sipBox setHidden:YES];
	}
	
	[networkBox setAutoresizingMask:NSViewMinYMargin];
	
	[h323Box setAutoresizingMask:NSViewMinYMargin];
	[h323Disclosure setAutoresizingMask:NSViewMinYMargin];
	[h323Title setAutoresizingMask:NSViewMinYMargin];
	
	[sipBox setAutoresizingMask:NSViewHeightSizable];
	[sipDisclosure setAutoresizingMask:NSViewMinYMargin];
	[sipTitle setAutoresizingMask:NSViewMinYMargin];
	
	[self resizeContentView];
	
	[networkBox setAutoresizingMask:NSViewHeightSizable];
	
	[h323Box setAutoresizingMask:NSViewMaxYMargin];
	[h323Disclosure setAutoresizingMask:NSViewMaxYMargin];
	[h323Title setAutoresizingMask:NSViewMaxYMargin];
	
	[sipBox setAutoresizingMask:NSViewMaxYMargin];
	[sipDisclosure setAutoresizingMask:NSViewMaxYMargin];
	[sipTitle setAutoresizingMask:NSViewMaxYMargin];
	
	if(showSIPDetails == YES)
	{
		[sipBox setHidden:NO];
	}
	
	[self _storeDetailStatus];
}

#pragma mark -
#pragma mark Private Methods

- (void)_updateNetworkStatus:(NSNotification *)notif
{
	XMUtils *utils = [XMUtils sharedInstance];
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	
	NSArray *localAddresses = [utils localAddresses];
	NSArray *localAddressInterfaces = [utils localAddressInterfaces];
	unsigned localAddressCount = [localAddresses count];
	
	if(localAddressCount == 0)
	{
		[ipAddressesField setStringValue:@""];
		[ipAddressSemaphoreView setImage:[NSImage imageNamed:@"semaphore_red"]];
		
		addressExtraHeight = 0;
		[self resizeContentView];
		
		[natTypeField setStringValue:@""];
		[natTypeSemaphoreView setImage:[NSImage imageNamed:@"semaphore_red"]];
		
		return;
	}
	
	NSMutableString *ipAddressString = [[NSMutableString alloc] initWithCapacity:30];
	unsigned i;
	
	NSString *stringToAppend = [[NSString alloc] initWithFormat:@"%@ (%@)", [localAddresses objectAtIndex:0],
																			[localAddressInterfaces objectAtIndex:0]];
	[ipAddressString appendString:stringToAppend];
	[stringToAppend release];
	
	for(i = 1; i < localAddressCount; i++)
	{
		NSString *stringToAppend = [[NSString alloc] initWithFormat:@"\n%@ (%@)", 
														[localAddresses objectAtIndex:i],
														[localAddressInterfaces objectAtIndex:i]];
		[ipAddressString appendString:stringToAppend];
		[stringToAppend release];
	}
	
	addressExtraHeight = (localAddressCount-1)*XM_IP_ADDRESSES_TEXT_FIELD_HEIGHT;
	
	if([[preferencesManager activeLocation] useSTUN])
	{
		NSString *externalAddress = [utils stunExternalAddress];
		if(externalAddress == nil)
		{
			externalAddress = [utils checkipExternalAddress];
		}
		
		if(externalAddress != nil && ![localAddresses containsObject:externalAddress])
		{
			[ipAddressString appendString:@"\n"];
			[ipAddressString appendString:externalAddress];
			[ipAddressString appendString:NSLocalizedString(@"XM_EXTERNAL_ADDRESS_SUFFIX", @"")];
			addressExtraHeight += XM_IP_ADDRESSES_TEXT_FIELD_HEIGHT;
		}
	}
	else if([[preferencesManager activeLocation] useAddressTranslation])
	{
		NSString *externalAddress = [utils checkipExternalAddress];
		
		if(externalAddress != nil && ![localAddresses containsObject:externalAddress])
		{
			[ipAddressString appendString:@"\n"];
			[ipAddressString appendString:externalAddress];
			[ipAddressString appendString:NSLocalizedString(@"XM_EXTERNAL_ADDRESS_SUFFIX", @"")];
			addressExtraHeight += XM_IP_ADDRESSES_TEXT_FIELD_HEIGHT;
		}
	}
	
	[ipAddressesField setStringValue:ipAddressString];
	[ipAddressesField setToolTip:ipAddressString];
	[ipAddressString release];
	[ipAddressSemaphoreView setImage:[NSImage imageNamed:@"semaphore_green"]];
	
	// Determining the NAT Type
	XMNATType natType = [utils natType];
	NSString *natTypeString = XMNATTypeString(natType);
	[natTypeField setStringValue:natTypeString];
	
	if(natType == XMNATType_Error ||
	   natType == XMNATType_SymmetricNAT ||
	   natType == XMNATType_BlockedNAT)
	{
		[natTypeSemaphoreView setImage:[NSImage imageNamed:@"semaphore_red"]];
	}
	else
	{
		[natTypeSemaphoreView setImage:[NSImage imageNamed:@"semaphore_green"]];
	}
	
	[self resizeContentView];
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
			[h323StatusField setStringValue:NSLocalizedString(@"Online", @"")];
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
					[gatekeeperField setStringValue:NSLocalizedString(@"XM_INFO_MODULE_REG_FAILURE", @"")];
					[gatekeeperSemaphoreView setImage:[NSImage imageNamed:@"semaphore_red"]];
					[phoneNumberField setTextColor:[NSColor disabledControlTextColor]];
				}
			}
			else
			{
				[gatekeeperField setStringValue:NSLocalizedString(@"XM_INFO_MODULE_NO_REG", @"")];
				[gatekeeperSemaphoreView setImage:nil];
				[phoneNumberField setStringValue:@""];
			}
		}
		else
		{
			[h323StatusField setStringValue:NSLocalizedString(@"XM_INFO_MODULE_PROTOCOL_FAILURE", @"")];
			[h323StatusSemaphoreView setImage:[NSImage imageNamed:@"semaphore_red"]];
			[gatekeeperField setStringValue:@""];
			[gatekeeperSemaphoreView setImage:nil];
			[phoneNumberField setStringValue:@""];
		}
	}
	else
	{
		[h323StatusField setStringValue:NSLocalizedString(@"XM_INFO_MODULE_NO_PROTOCOL", @"")];
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
					[registrarField setStringValue:NSLocalizedString(@"XM_INFO_MODULE_REG_FAILURE", @"")];
					[registrarSemaphoreView setImage:[NSImage imageNamed:@"semaphore_red"]];
					[sipUsernameField setStringValue:@""];
				}
			}
			else
			{
				[registrarField setStringValue:NSLocalizedString(@"XM_INFO_MODULE_NO_REG", @"")];
				[registrarSemaphoreView setImage:nil];
				[sipUsernameField setStringValue:@""];
			}
		}
		else
		{
			[sipStatusField setStringValue:NSLocalizedString(@"XM_INFO_MODULE_PROTOCOL_FAILURE", @"")];
			[sipStatusSemaphoreView setImage:[NSImage imageNamed:@"semaphore_red"]];
			[registrarField setStringValue:@""];
			[registrarSemaphoreView setImage:nil];
			[sipUsernameField setStringValue:@""];
		}
	}
	else
	{
		[sipStatusField setStringValue:NSLocalizedString(@"XM_INFO_MODULE_NO_PROTOCOL", @"")];
		[sipStatusSemaphoreView setImage:nil];
		[registrarField setStringValue:@""];
		[registrarSemaphoreView setImage:nil];
		[sipUsernameField setStringValue:@""];
	}
}

- (void)_storeDetailStatus
{
	unsigned status = 0;
	
	if(showH323Details == YES)
	{
		status += XM_SHOW_H323_DETAILS;
	}
	if(showSIPDetails == YES)
	{
		status += XM_SHOW_SIP_DETAILS;
	}
	
	[[NSUserDefaults standardUserDefaults] setInteger:status forKey:XM_INFO_MODULE_DETAIL_STATUS_KEY];
}

@end
