/*
 * $Id: XMAddressBookModule.m,v 1.24 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#import "XMAddressBookModule.h"

#import <AddressBook/AddressBook.h>
#import <AddressBook/AddressBookUI.h>

#import "XMeeting.h"
#import "XMCallAddressManager.h"
#import "XMAddressBookManager.h"
#import "XMAddressBookRecord.h"
#import "XMPreferencesManager.h"
#import "XMMainWindowController.h"

#define XM_DEFAULT_TAG 20
#define XM_HOME_TAG 21
#define XM_WORK_TAG 22
#define XM_OTHER_TAG 23
#define XM_CUSTOM_TAG 24

NSString *XMAddressBookPeoplePickerViewAutosaveName = @"XMeetingAddressBookPeoplePickerView";

@interface XMAddressBookModule (PrivateMethods)

- (BOOL)_canEditSelectedRecord;
- (void)_recordSelectionDidChange:(NSNotification *)notif;

- (void)_editRecord:(XMAddressBookRecord *)record;
- (void)_validateCallButton;

- (void)_displayProtocol:(XMCallProtocol)callProtocol;
- (void)_validateLabel;

- (void)_validateSpecificGatekeeperPart;
- (void)_validateEditOKButton;

- (void)_preferencesDidChange:(NSNotification *)notif;

@end

@implementation XMAddressBookModule

#pragma mark Init & Deallocation Methods

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
	contentViewMinSize = [contentView frame].size;
	contentViewSize = contentViewMinSize;
	
	[addressBookView setAutosaveName:XMAddressBookPeoplePickerViewAutosaveName];
	[addressBookView setTarget:self];
	[addressBookView setNameDoubleAction:@selector(addressBookDoubleAction:)];
	
	// The address resource is stored in a NSData representation to allow all relevant information
	// to be stored. In addition, we store a more human readable form under
	// XMAddressBookProperty_HumanReadableCallAddress. This way, we maintain
	// both a more human readable representation to display in the PeoplePickerView and
	// the complete call address used for the XMeeting framework
	[addressBookView addProperty:XMAddressBookProperty_HumanReadableCallAddress];
	[addressBookView setColumnTitle:NSLocalizedString(@"XM_ADDRESS_BOOK_MODULE_ADDRESS_TITLE", @"") forProperty:XMAddressBookProperty_HumanReadableCallAddress];
	
	// eventually display phone numbers
	[addressBookView setColumnTitle:NSLocalizedString(@"XM_ADDRESS_BOOK_MODULE_PHONE_TITLE", @"") forProperty:kABPhoneProperty];
	
	// registering some notification
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

	[notificationCenter addObserver:self
						   selector:@selector(_recordSelectionDidChange:)
							   name:ABPeoplePickerValueSelectionDidChangeNotification
							 object:nil];
	[notificationCenter addObserver:self
						   selector:@selector(_preferencesDidChange:)
							   name:XMNotification_PreferencesManagerDidChangePreferences
							 object:nil];
	
	// setup of interface
	[self _preferencesDidChange:nil];
	
	// validating the buttons
	[self _validateCallButton];
	
	//set up cog-wheel menu
	[actionButton sendActionOn:NSLeftMouseDownMask];
	[actionPopup selectItem: nil];
	
}

#pragma mark -
#pragma mark XMInspectorModule Methods

- (NSString *)identifier
{
	return @"AddressBook";
}

- (NSString *)name
{
	return NSLocalizedString(@"XM_ADDRESS_BOOK_MODULE_NAME", @"");
}

- (NSImage *)image
{
	return [NSImage imageNamed:@"AddressBook_16"];
}

- (NSView *)contentView
{
	if(contentView == nil)
	{
		[NSBundle loadNibNamed:@"AddressBook" owner:self];
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

#pragma mark -
#pragma mark Action Methods

- (IBAction)call:(id)sender
{
	NSArray *selectedRecords = [addressBookView selectedRecords];
	
	if([selectedRecords count] == 0)
	{
		return;
	}
	
	ABPerson *person = (ABPerson *)[selectedRecords objectAtIndex:0];
	NSArray *selectedIdentifiers = [addressBookView selectedIdentifiersForPerson:person];
	
	NSString *identifier = nil;
	if([selectedIdentifiers count] != 0)
	{
		identifier = (NSString *)[selectedIdentifiers objectAtIndex:0];
	}
	
	BOOL isPhoneNumber = NO;
	if([[addressBookView displayedProperty] isEqualToString:kABPhoneProperty])
	{
		isPhoneNumber = YES;
	}
	
	XMAddressBookRecord *record = [[XMAddressBookManager sharedInstance] recordForPerson:person identifier:identifier
																		   isPhoneNumber:isPhoneNumber];

	[[XMCallAddressManager sharedInstance] makeCallToAddress:record];
}

- (IBAction)newRecord:(id)sender
{
	[firstNameField setStringValue:@""];
	[lastNameField setStringValue:@""];
	[organizationField setStringValue:@""];
	[isOrganizationSwitch setState:NSOffState];
	
	[NSApp beginSheet:newRecordSheet modalForWindow:[contentView window] modalDelegate:nil
	   didEndSelector:NULL contextInfo:NULL];
	[newRecordSheet makeFirstResponder:firstNameField];
}

- (IBAction)cogWheelAction:(id)sender
{
    [[actionPopup cell] performClickWithFrame:[sender frame] inView:[sender superview]];    
	[actionPopup selectItem:nil];
}

- (IBAction)editAddress:(id)sender
{
	NSArray *selectedRecords = [addressBookView selectedRecords];
	
	if([selectedRecords count] == 0)
	{
		return;
	}
	
	ABPerson *person = (ABPerson *)[selectedRecords objectAtIndex:0];
	NSArray *selectedIdentifiers = [addressBookView selectedIdentifiersForPerson:person];
	
	NSString *identifier = nil;
	if([selectedIdentifiers count] != 0)
	{
		identifier = (NSString *)[selectedIdentifiers objectAtIndex:0];
	}
	
	XMAddressBookRecord *record = [[XMAddressBookManager sharedInstance] recordForPerson:person identifier:identifier
																		   isPhoneNumber:NO];
	[self _editRecord:record];
}

- (IBAction)newAddress:(id)sender
{
	NSArray *selectedRecords = [addressBookView selectedRecords];
	
	if([selectedRecords count] == 0)
	{
		return;
	}
	
	ABPerson *person = (ABPerson *)[selectedRecords objectAtIndex:0];
	
	XMAddressBookRecord *record = [[XMAddressBookManager sharedInstance] recordForPerson:person identifier:nil
																		   isPhoneNumber:NO];
	[self _editRecord:record];
}

- (IBAction)makePrimaryAddress:(id)sender
{
	NSArray *selectedRecords = [addressBookView selectedRecords];
	
	if([selectedRecords count] == 0)
	{
		return;
	}
	
	ABPerson *person = (ABPerson *)[selectedRecords objectAtIndex:0];
	
	NSArray *selectedIdentifiers = [addressBookView selectedIdentifiersForPerson:person];
	
	if([selectedIdentifiers count] == 0)
	{
		return;
	}
	
	NSString *identifier = (NSString *)[selectedIdentifiers objectAtIndex:0];
	
	[[XMAddressBookManager sharedInstance] setPrimaryAddressForPerson:person withIdentifier:identifier];
}

- (IBAction)launchAddressBook:(id)sender
{
	[addressBookView editInAddressBook:sender];
}

- (IBAction)addressBookDoubleAction:(id)sender
{
	if([[addressBookView displayedProperty] isEqualToString:kABPhoneProperty])
	{
		[self launchAddressBook:nil];
		return;
	}
	
	BOOL isEdit = [self _canEditSelectedRecord];
	
	if(isEdit)
	{
		[self editAddress:self];
	}
	else
	{
		[self newAddress:self];
	}
}

- (IBAction)callProtocolSelected:(id)sender
{
	XMCallProtocol callProtocol;
	
	if([callProtocolPopUp indexOfSelectedItem] == 0)
	{
		callProtocol = XMCallProtocol_H323;
	}
	else
	{
		callProtocol = XMCallProtocol_SIP;
	}
	
	[self _validateEditOKButton];
	[self _displayProtocol:callProtocol];
}

- (IBAction)labelSelected:(id)sender
{
	[self _validateLabel];
	[self _validateEditOKButton];
}

- (IBAction)endEditRecordSheet:(id)sender
{	
	if(sender == deleteButton)
	{
		[editedRecord setCallAddress:nil label:nil];
	}
	else if(sender == okButton)
	{
		if(editedAddress == nil)
		{
			editedAddress = [[XMGeneralPurposeAddressResource alloc] init];
		}
		
		NSString *addressPart = nil;
		XMCallProtocol callProtocol;
		NSString *gatekeeperHost = nil;
		NSString *gatekeeperUsername = nil;
		NSString *gatekeeperPhoneNumber = nil;
		
		if([callProtocolPopUp indexOfSelectedItem] == 0)
		{ 
			// H.323
			callProtocol = XMCallProtocol_H323;
			addressPart = [h323CallAddressField stringValue];
			
			if([useSpecificGatekeeperSwitch state] == NSOnState)
			{
				gatekeeperHost = [h323GatekeeperHostField stringValue];
				gatekeeperUsername = [h323GatekeeperUsernameField stringValue];
				gatekeeperPhoneNumber = [h323GatekeeperPhoneNumberField stringValue];
			}
		}
		else
		{
			callProtocol = XMCallProtocol_SIP;
			addressPart = [sipCallAddressField stringValue];
		}
		
		[editedAddress setAddress:addressPart];
		[editedAddress setCallProtocol:callProtocol];
		[editedAddress setValue:gatekeeperHost forKey:XMKey_PreferencesGatekeeperAddress];
		[editedAddress setValue:gatekeeperUsername forKey:XMKey_PreferencesGatekeeperTerminalAlias1];
		[editedAddress setValue:gatekeeperPhoneNumber forKey:XMKey_PreferencesGatekeeperTerminalAlias2];
		
		int tag = [[labelPopUp selectedItem] tag];
		NSString *label = nil;
		if(tag == XM_DEFAULT_TAG)
		{
			if(callProtocol == XMCallProtocol_H323)
			{
				label = @"H.323";
			}
			else
			{
				label = @"SIP";
			}
		}
		else if(tag == XM_HOME_TAG)
		{
			label = kABHomeLabel;
		}
		else if(tag == XM_WORK_TAG)
		{
			label = kABWorkLabel;
		}
		else if(tag == XM_OTHER_TAG)
		{
			label = kABOtherLabel;
		}
		else
		{
			label = [labelField stringValue];
		}
		[editedRecord setCallAddress:editedAddress label:label];
				
		// in case this is a new record, we add it. This method does nothing if the record is already contained.
		XMAddressBookManager *addressBookManager = [XMAddressBookManager sharedInstance];
		[addressBookManager addRecord:editedRecord];
	}
	
	[NSApp endSheet:editRecordSheet];
	[editRecordSheet orderOut:self];
	
	[editedRecord release];
	[editedAddress release];
	editedRecord = nil;
	editedAddress = nil;
	
	[self _validateCallButton];
}

- (IBAction)toggleUseSpecificGatekeeper:(id)sender
{
	[self _validateSpecificGatekeeperPart];
	[self _validateEditOKButton];
}

- (IBAction)addNewRecord:(id)sender
{
	BOOL isCompany = ([isOrganizationSwitch state] == NSOnState);
	XMAddressBookManager *addressBookManager = [XMAddressBookManager sharedInstance];
	ABPerson *person = [addressBookManager createPersonWithFirstName:[firstNameField stringValue]
															lastName:[lastNameField stringValue]
														 companyName:[organizationField stringValue]
														   isCompany:isCompany];
	
	[self cancelNewRecord:self];
	
	XMAddressBookRecord *record = [addressBookManager recordForPerson:person identifier:nil isPhoneNumber:NO];
	
	[self _editRecord:record];
}

- (IBAction)cancelNewRecord:(id)sender
{
	[NSApp endSheet:newRecordSheet];
	[newRecordSheet orderOut:self];
}

#pragma mark -
#pragma mark Delegate Methods

- (void)controlTextDidChange:(NSNotification *)notif
{
	[self _validateEditOKButton];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	int tag = [menuItem tag];
	
	if(tag == 0)
	{
		return [self _canEditSelectedRecord];
	}
	else if(tag == 1)
	{
		NSArray *selectedRecords = [addressBookView selectedRecords];
		if([selectedRecords count] == 0)
		{
			return NO;
		}
		
		if([[addressBookView displayedProperty] isEqualToString:kABPhoneProperty])
		{
			return NO;
		}
	}
	else if(tag == 2)
	{
		return [self _canEditSelectedRecord];
	}

	return YES;
}

#pragma mark Private Methods

- (BOOL)_canEditSelectedRecord
{
	if([[addressBookView displayedProperty] isEqualToString:kABPhoneProperty])
	{
		return NO;
	}
	
	NSArray *selectedRecords = [addressBookView selectedRecords];
	
	if([selectedRecords count] == 0)
	{
		return NO;
	}
	
	ABPerson *selectedRecord = (ABPerson *)[selectedRecords objectAtIndex:0];
	
	NSArray *selectedIdentifiers = [addressBookView selectedIdentifiersForPerson:selectedRecord];
	
	if([selectedIdentifiers count] == 0)
	{
		return NO;
	}
	
	return YES;
}

- (void)_recordSelectionDidChange:(NSNotification *)notif
{
	[self _validateCallButton];
}

- (void)_editRecord:(XMAddressBookRecord *)record
{
	if(editedRecord != nil)
	{
		[editedRecord release];
	}
	editedRecord = [record retain];
	
	if(editedAddress != nil)
	{
		[editedAddress release];
	}
	editedAddress = (XMGeneralPurposeAddressResource *)[[record callAddress] retain];
	
	BOOL enableDeleteButton;
	XMCallProtocol callProtocol;
	unsigned callProtocolPopUpItemIndex;
	NSString *h323Address;
	int useSpecificGKSwitchState;
	NSString *gatekeeperHost;
	NSString *gatekeeperUsername;
	NSString *gatekeeperPhoneNumber;
	NSString *sipAddress;
	
	if(editedAddress == nil)
	{
		enableDeleteButton = NO;
		callProtocol = XMCallProtocol_H323;
		callProtocolPopUpItemIndex = 0;
		h323Address = @"";
		useSpecificGKSwitchState = NSOffState;
		gatekeeperHost = @"";
		gatekeeperUsername = @"";
		gatekeeperPhoneNumber = @"";
		sipAddress = @"";
	}
	else
	{
		enableDeleteButton = YES;
		NSString *address = [editedAddress address];
		callProtocol = [editedAddress callProtocol];
		if(callProtocol == XMCallProtocol_H323)
		{
			callProtocolPopUpItemIndex = 0;
			h323Address = address;
			gatekeeperHost = [editedAddress valueForKey:XMKey_PreferencesGatekeeperAddress];
			gatekeeperUsername = [editedAddress valueForKey:XMKey_PreferencesGatekeeperTerminalAlias1];
			gatekeeperPhoneNumber = [editedAddress valueForKey:XMKey_PreferencesGatekeeperTerminalAlias2];
			
			if(gatekeeperHost != nil && ![gatekeeperHost isEqualToString:@""] &&
			   gatekeeperUsername != nil && ![gatekeeperUsername isEqualToString:@""] &&
			   gatekeeperPhoneNumber != nil && ![gatekeeperPhoneNumber isEqualToString:@""])
			{
				useSpecificGKSwitchState = NSOnState;
			}
			else
			{
				useSpecificGKSwitchState = NSOffState;
				gatekeeperHost = @"";
				gatekeeperUsername = @"";
				gatekeeperPhoneNumber = @"";
			}
					
			sipAddress = @"";
		}
		else
		{
			callProtocolPopUpItemIndex = 1;
			h323Address = @"";
			useSpecificGKSwitchState = NSOffState;
			gatekeeperHost = @"";
			gatekeeperUsername = @"";
			gatekeeperPhoneNumber = @"";
			sipAddress = address;
		}
	}
	
	NSString *recordDisplayName = [record displayName];
	[recordNameField setStringValue:recordDisplayName];
	
	NSString *label = [editedRecord label];
	int tag;
	
	if(label == nil ||
	   [label isEqualToString:@"H.323"] ||
	   [label isEqualToString:@"SIP"])
	{
		tag = XM_DEFAULT_TAG;
		label = @"";
	}
	else if([label isEqualToString:kABHomeLabel])
	{
		tag = XM_HOME_TAG;
		label = @"";
	}
	else if([label isEqualToString:kABWorkLabel])
	{
		tag = XM_WORK_TAG;
		label = @"";
	}
	else if([label isEqualToString:kABOtherLabel])
	{
		tag = XM_OTHER_TAG;
		label = @"";
	}
	else if(label != nil &&
			![label isEqualToString:@"H.323"] &&
			![label isEqualToString:@"SIP"])
	{
		tag = XM_CUSTOM_TAG;
	}
	
	[labelPopUp selectItemWithTag:tag];
	[labelField setStringValue:label];
	
	[deleteButton setEnabled:enableDeleteButton];
	[callProtocolPopUp selectItemAtIndex:callProtocolPopUpItemIndex];
	
	[h323CallAddressField setStringValue:h323Address];
	[useSpecificGatekeeperSwitch setState:useSpecificGKSwitchState];
	[h323GatekeeperHostField setStringValue:gatekeeperHost];
	[h323GatekeeperUsernameField setStringValue:gatekeeperUsername];
	[h323GatekeeperPhoneNumberField setStringValue:gatekeeperPhoneNumber];
	
	[sipCallAddressField setStringValue:sipAddress];
	
	[self _validateSpecificGatekeeperPart];
	
	[self _validateEditOKButton];
	[self _validateLabel];
	[self _displayProtocol:callProtocol];
	
	[NSApp beginSheet:editRecordSheet modalForWindow:[contentView window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (void)_validateCallButton
{
	NSArray *selectedRecords = [addressBookView selectedRecords];
	
	BOOL enableCallButton = YES;
	
	if([selectedRecords count] == 0)
	{
		enableCallButton = NO;
	}
	else
	{
		ABPerson *person = (ABPerson *)[selectedRecords objectAtIndex:0];
		NSString *displayedProperty = [addressBookView displayedProperty];
		
		if([displayedProperty isEqualToString:kABPhoneProperty])
		{
			if([person valueForProperty:kABPhoneProperty] == nil)
			{
				enableCallButton = NO;
			}
		}
		else if([person valueForProperty:XMAddressBookProperty_HumanReadableCallAddress] == nil)
		{
			enableCallButton = NO;
		}
	}
	
	[callButton setEnabled:enableCallButton];
}

- (void)_displayProtocol:(XMCallProtocol)protocol
{
	NSView *view = nil;
	NSString *labelString = nil;
	
	if(protocol == XMCallProtocol_H323)
	{
		view = h323View;
		labelString = @"H.323";
	}
	else
	{
		view = sipView;
		labelString = @"SIP";
	}
	
	if([addressEditBox contentView] == view)
	{
		return;
	}
	
	NSRect bounds = [addressEditBox bounds];
	NSRect newBounds = [view bounds];
	
	int widthDifference = (int)newBounds.size.width - (int)bounds.size.width;
	int heightDifference = (int)newBounds.size.height - (int)bounds.size.height;
	
	NSRect windowFrame = [editRecordSheet frame];
	windowFrame.size.width += widthDifference;
	windowFrame.origin.y -= heightDifference;
	windowFrame.size.height += heightDifference;
	
	[addressEditBox setContentView:nil];
	
	[editRecordSheet setFrame:windowFrame display:YES animate:YES];
	
	[addressEditBox setContentView:view];
	
	[editRecordSheet recalculateKeyViewLoop];
	
	int index = [labelPopUp indexOfSelectedItem];
	[[labelPopUp itemAtIndex:0] setTitle:labelString];
	[labelPopUp selectItemAtIndex:index];
}

- (void)_validateLabel
{
	int tag = [[labelPopUp selectedItem] tag];
	
	BOOL enableLabelField = NO;
	
	if(tag == XM_CUSTOM_TAG)
	{
		enableLabelField = YES;
	}
	
	[labelField setEnabled:enableLabelField];
}

- (void)_validateSpecificGatekeeperPart
{
	BOOL enableControls = NO;
	if([useSpecificGatekeeperSwitch state] == NSOnState)
	{
		enableControls = YES;
	}
	
	[h323GatekeeperHostField setEnabled:enableControls];
	[h323GatekeeperUsernameField setEnabled:enableControls];
	[h323GatekeeperPhoneNumberField setEnabled:enableControls];
}

- (void)_validateEditOKButton
{
	BOOL enableOKButton = YES;
	
	int tag = [[labelPopUp selectedItem] tag];
	if(tag == XM_CUSTOM_TAG && [[labelField stringValue] isEqualToString:@""])
	{
		enableOKButton = NO;
	}
	else if([callProtocolPopUp indexOfSelectedItem] == 0)
	{
		// H.323
		if([[h323CallAddressField stringValue] isEqualToString:@""])
		{
			enableOKButton = NO;
		}
		else if([useSpecificGatekeeperSwitch state] == NSOnState)
		{
			if([[h323GatekeeperHostField stringValue] isEqualToString:@""] ||
			   [[h323GatekeeperUsernameField stringValue] isEqualToString:@""] ||
			   [[h323GatekeeperPhoneNumberField stringValue] isEqualToString:@""])
			{
				enableOKButton = NO;
			}
		}
	}
	else
	{
		// SIP
		
		if([[sipCallAddressField stringValue] isEqualToString:@""])
		{
			enableOKButton = NO;
		}
	}
	
	[okButton setEnabled:enableOKButton];
}

- (void)_preferencesDidChange:(NSNotification *)notif
{
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	
	if([preferencesManager enableAddressBookPhoneNumbers])
	{
		[addressBookView addProperty:kABPhoneProperty];
	}
	else
	{
		[addressBookView removeProperty:kABPhoneProperty];
	}
}

@end