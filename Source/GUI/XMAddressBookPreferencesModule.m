/*
 * $Id: XMAddressBookPreferencesModule.m,v 1.4 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2006-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2008 Hannes Friederich. All rights reserved.
 */

#import "XMAddressBookPreferencesModule.h"
#import "XMPreferencesWindowController.h"
#import "XMPreferencesManager.h"

@interface XMAddressBookPreferencesModule (PrivateMethods)

- (void)_validateProtocolMatrix;

@end

@implementation XMAddressBookPreferencesModule

- (id)init
{
	prefWindowController = [[XMPreferencesWindowController sharedInstance] retain];
	
	return self;
}

- (void)awakeFromNib
{
	contentViewHeight = [contentView frame].size.height;
	[prefWindowController addPreferencesModule:self];
}

- (void)dealloc
{
	[prefWindowController release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark XMPreferencesModule methods

- (unsigned)position
{
	return 6;
}

- (NSString *)identifier
{
	return @"XMeeting_AddressBookPreferencesModule";
}

- (NSString *)toolbarLabel
{
	return NSLocalizedString(@"XM_ADDRESS_BOOK_PREFERENCES_NAME", @"");
}

- (NSImage *)toolbarImage
{
	return [NSImage imageNamed:@"AddressBook"];
}

- (NSString *)toolTipText
{
	return NSLocalizedString(@"XM_ADDRESS_BOOK_PREFERENCES_TOOLTIP", @"");
}

- (NSView *)contentView
{
	return contentView;
}

- (float)contentViewHeight
{
	return contentViewHeight;
}

- (void)loadPreferences
{
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	
	int state = ([preferencesManager searchAddressBookDatabase] == YES) ? NSOnState : NSOffState;
	[enableABDatabaseSearchSwitch setState:state];
	
	state = ([preferencesManager enableAddressBookPhoneNumbers] == YES) ? NSOnState : NSOffState;
	[enableABPhoneNumbersSwitch setState:state];
	
	XMCallProtocol callProtocol = [preferencesManager addressBookPhoneNumberProtocol];
	[phoneNumberProtocolMatrix selectCellWithTag:(int)callProtocol];
	
	[self _validateProtocolMatrix];
}

- (void)savePreferences
{
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	
	BOOL flag = ([enableABDatabaseSearchSwitch state] == NSOnState) ? YES : NO;
	[preferencesManager setSearchAddressBookDatabase:flag];
	
	flag = ([enableABPhoneNumbersSwitch state] == NSOnState) ? YES : NO;
	[preferencesManager setEnableAddressBookPhoneNumbers:flag];
	
	XMCallProtocol callProtocol = (XMCallProtocol)[[phoneNumberProtocolMatrix selectedCell] tag];
	[preferencesManager setAddressBookPhoneNumberProtocol:callProtocol];
}

- (void)becomeActiveModule
{
}

#pragma mark -
#pragma mark Action Methods

- (IBAction)defaultAction:(id)sender
{
	[prefWindowController notePreferencesDidChange];
}

- (IBAction)toggleEnableABPhoneNumbers:(id)sender
{
	[self _validateProtocolMatrix];
	[self defaultAction:self];
}

#pragma mark -
#pragma mark Private Methods

- (void)_validateProtocolMatrix
{
	if([enableABPhoneNumbersSwitch state] == NSOnState)
	{
		[phoneNumberProtocolMatrix setEnabled:YES];
	}
	else
	{
		[phoneNumberProtocolMatrix setEnabled:NO];
	}
}

@end
