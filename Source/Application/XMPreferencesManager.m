/*
 * $Id: XMPreferencesManager.m,v 1.27 2006/06/27 18:05:32 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMPreferencesManager.h"

#import "XMH323Account.h"
#import "XMSIPAccount.h"
#import "XMLocation.h"

NSString *XMNotification_PreferencesManagerDidChangePreferences = @"XMeeting_PreferencesManagerDidChangePreferences";
NSString *XMNotification_PreferencesManagerDidChangeActiveLocation = @"XMeeting_PreferencesManagerDidChangeActiveLocation";

NSString *XMKey_PreferencesManagerPreferencesAvailable = @"XMeeting_PreferencesAvailable";
NSString *XMKey_PreferencesManagerH323Accounts = @"XMeeting_H323Accounts";
NSString *XMKey_PreferencesManagerSIPAccounts = @"XMeeting_SIPAccounts";
NSString *XMKey_PreferencesManagerLocations = @"XMeeting_Locations";
NSString *XMKey_PreferencesManagerActiveLocation = @"XMeeting_ActiveLocation";
NSString *XMKey_PreferencesManagerUserName = @"XMeeting_UserName";
NSString *XMKey_PreferencesManagerAutomaticallyAcceptIncomingCalls = @"XMeeting_AutomaticallyAcceptIncomingCalls";
NSString *XMKey_PreferencesManagerEnablePTrace = @"XMeeting_EnablePTrace";
NSString *XMKey_PreferencesManagerPTraceFilePath = @"XMeeting_PTraceFilePath";
NSString *XMKey_PreferencesManagerAutomaticallyEnterFullScreen = @"XMeeting_AutomaticallyEnterFullScreen";
NSString *XMKey_PreferencesManagerShowSelfViewMirrored = @"XMeeting_ShowSelfViewMirrored";
NSString *XMKey_PreferencesManagerAutomaticallyHideInCallControls = @"XMeeting_AutomaticallyHideInCallControls";
NSString *XMKey_PreferencesManagerInCallControlHideAndShowEffect = @"XMeeting_InCallControlHideAndShowEffect";
NSString *XMKey_PreferencesManagerAlertIncomingCalls = @"XMeeting_AlertIncomingCalls";
NSString *XMKey_PreferencesManagerIncomingCallAlertType = @"XMeeting_IncomingCallAlertType";
NSString *XMKey_PreferencesManagerPreferredAudioOutputDevice = @"XMeeting_PreferredAudioOutputDevice";
NSString *XMKey_PreferencesManagerPreferredAudioInputDevice = @"XMeeting_PreferredAudioInputDevice";
NSString *XMKey_PreferencesManagerDisabledVideoModules = @"XMeeting_DisabledVideoModules";
NSString *XMKey_PreferencesManagerPreferredVideoInputDevice = @"XMeeting_PreferredVideoInputDevice";
NSString *XMKey_PreferencesManagerVideoManagerSettings = @"XMeeting_VideoManagerSettings";

NSString *XMKey_PreferencesManagerSearchAddressBookDatabase = @"XMeeting_SearchAddressBookDatabase";
NSString *XMKey_PreferencesManagerEnableAddressBookPhoneNumbers = @"XMeeting_EnableAddressBookPhoneNumbers";
NSString *XMKey_PreferencesManagerAddressBookPhoneNumberProtocol = @"XMeeting_AddressBookPhoneNumberProtocol";

@interface XMPreferencesManager (PrivateMethods)

- (id)_init;
- (void)_setup;

- (NSString *)_passwordForServiceName:(NSString *)serviceName accountName:(NSString *)accountName;
- (void)_setPassword:(NSString *)password forServiceName:(NSString *)serviceName accountName:(NSString *)accountName;

- (void)_setInitialAudioDevices;

- (void)_setInitialVideoInputDevice:(NSNotification *)notif;

- (void)_updateCallManagerPreferences:(NSNotification *)notif;

@end

@implementation XMPreferencesManager

#pragma mark -
#pragma mark Class Methods

+ (XMPreferencesManager *)sharedInstance
{
	static XMPreferencesManager *sharedInstance = nil;
	
	if(!sharedInstance)
	{
		sharedInstance = [[XMPreferencesManager alloc] _init];
		[sharedInstance _setup];
	}

	return sharedInstance;
}

+ (BOOL)doesHavePreferences
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	BOOL doesHavePreferences = [userDefaults boolForKey:XMKey_PreferencesManagerPreferencesAvailable];
	
	// this is a one-time check, thus next time we return YES
	[userDefaults setBool:YES forKey:XMKey_PreferencesManagerPreferencesAvailable];
	
	return doesHavePreferences;
}

+ (BOOL)enablePTrace
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:XMKey_PreferencesManagerEnablePTrace];
}

+ (void)setEnablePTrace:(BOOL)flag
{
	[[NSUserDefaults standardUserDefaults] setBool:flag forKey:XMKey_PreferencesManagerEnablePTrace];
}

+ (NSString *)pTraceFilePath
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:XMKey_PreferencesManagerPTraceFilePath];
}

+ (void)setPTraceFilePath:(NSString *)path
{
	[[NSUserDefaults standardUserDefaults] setObject:path forKey:XMKey_PreferencesManagerPTraceFilePath];
}

#pragma mark -
#pragma mark Init & Deallocation Methods

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)_init
{
	self = [super init];
	
	h323Accounts = nil;
	sipAccounts = nil;
	locations = nil;
	
	return self;
}

- (void)_setup
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	/* Register the default values of the preferences */
	NSMutableDictionary *defaultsDict = [[NSMutableDictionary alloc] init];
	
	/* intermediate code to make sure that at least one location is present in UserDefaults */
	/* later, this will be replaced by some sort of wizard popping up */
	XMLocation *defaultLocation = [[XMLocation alloc] initWithName:NSLocalizedString(@"XM_DEFAULT_LOCATION_TEXT", @"")];
	NSDictionary *dict = [defaultLocation dictionaryRepresentationWithH323Accounts:nil sipAccounts:nil];
	NSArray *defaultLocationArray = [NSArray arrayWithObject:dict];
	[defaultsDict setObject:defaultLocationArray forKey:XMKey_PreferencesManagerLocations];
	[defaultLocation release];
	
	[defaultsDict setObject:NSFullUserName() forKey:XMKey_PreferencesManagerUserName];
	
	NSNumber *number = [[NSNumber alloc] initWithBool:NO];
	[defaultsDict setObject:number forKey:XMKey_PreferencesManagerAutomaticallyAcceptIncomingCalls];
	
	[defaultsDict setObject:number forKey:XMKey_PreferencesManagerEnablePTrace];
	
	[defaultsDict setObject:number forKey:XMKey_PreferencesManagerShowSelfViewMirrored];
	
	[number release];
	
	number = [[NSNumber alloc] initWithBool:NO];
	[defaultsDict setObject:number forKey:XMKey_PreferencesManagerAutomaticallyHideInCallControls];
	[number release];
	
	number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)XMInCallControlHideAndShowEffect_Fade];
	[defaultsDict setObject:number forKey:XMKey_PreferencesManagerInCallControlHideAndShowEffect];
	[number release];
	
	number = [[NSNumber alloc] initWithBool:YES];
	[defaultsDict setObject:number forKey:XMKey_PreferencesManagerAlertIncomingCalls];
	[number release];
	
	number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)XMIncomingCallAlertType_Ringing];
	[defaultsDict setObject:number forKey:XMKey_PreferencesManagerIncomingCallAlertType];
	[number release];
	
	NSArray *initialDisabledVideoModules = [[NSArray alloc] initWithObjects:@"XMStillImageVideoInputModule", @"XMScreenVideoInputModule", nil];
	[defaultsDict setObject:initialDisabledVideoModules forKey:XMKey_PreferencesManagerDisabledVideoModules];
	[initialDisabledVideoModules release];
	
	number = [[NSNumber alloc] initWithBool:YES];
	[defaultsDict setObject:number forKey:XMKey_PreferencesManagerSearchAddressBookDatabase];
	[number release];
	
	number = [[NSNumber alloc] initWithBool:NO];
	[defaultsDict setObject:number forKey:XMKey_PreferencesManagerEnableAddressBookPhoneNumbers];
	[number release];
	
	number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)XMCallProtocol_H323];
	[defaultsDict setObject:number forKey:XMKey_PreferencesManagerAddressBookPhoneNumberProtocol];
	[number release];
	
	[userDefaults registerDefaults:defaultsDict];
	[defaultsDict release];
	
	/* getting the h323 accounts from UserDefaults */
	h323Accounts = [[NSMutableArray alloc] initWithCapacity:1];
	NSArray *dictArray = (NSArray *)[userDefaults objectForKey:XMKey_PreferencesManagerH323Accounts];
	if(dictArray != nil)
	{
		unsigned count = [dictArray count];
		unsigned i;
		
		for(i = 0; i < count; i++)
		{
			NSDictionary *dict = (NSDictionary *)[dictArray objectAtIndex:i];
			XMH323Account *h323Account = [[XMH323Account alloc] initWithDictionary:dict];
			[h323Accounts addObject:h323Account];
			[h323Account release];
		}
	}
	
	/* getting the SIP accounts from UserDefaults */
	sipAccounts = [[NSMutableArray alloc] initWithCapacity:1];
	dictArray = (NSArray *)[userDefaults objectForKey:XMKey_PreferencesManagerSIPAccounts];
	if(dictArray != nil)
	{
		unsigned count = [dictArray count];
		unsigned i;
		
		for(i = 0; i < count; i++)
		{
			NSDictionary *dict = (NSDictionary *)[dictArray objectAtIndex:i];
			XMSIPAccount *sipAccount = [[XMSIPAccount alloc] initWithDictionary:dict];
			[sipAccounts addObject:sipAccount];
			[sipAccount release];
		}
	}
	
	/* getting the locations list from UserDefaults */
	locations = [[NSMutableArray alloc] initWithCapacity:1];
	dictArray = (NSArray *)[userDefaults objectForKey:XMKey_PreferencesManagerLocations];
	if(dictArray != nil)
	{
		unsigned count = [dictArray count];
		unsigned i;
		
		for(i = 0; i < count; i++)
		{
			NSDictionary *dict = (NSDictionary *)[dictArray objectAtIndex:i];
			XMLocation *location = [[XMLocation alloc] initWithDictionary:dict
															 h323Accounts:h323Accounts
															  sipAccounts:sipAccounts];
			[locations addObject:location];
			[location release];
		}
	}
	
	// since NSUserDefaults returns 0 if no value for the Key is found, we
	// simply increase the stored value by one;
	int index = [userDefaults integerForKey:XMKey_PreferencesManagerActiveLocation];
	if(index == 0)
	{
		activeLocation = 0;
	}
	else
	{
		activeLocation = (unsigned)(index-1);
	}
	
	automaticallyAcceptIncomingCalls = [userDefaults boolForKey:XMKey_PreferencesManagerAutomaticallyAcceptIncomingCalls];
	
	XMVideoManager *videoManager = [XMVideoManager sharedInstance];
	NSArray *disabledVideoModules = [self disabledVideoModules];
	if(disabledVideoModules != nil)
	{
		unsigned i;
		unsigned count = [videoManager videoModuleCount];
		
		for(i = 0; i < count; i++)
		{
			id<XMVideoModule> module = [videoManager videoModuleAtIndex:i];
			
			NSString *identifier = [module identifier];
			if([disabledVideoModules containsObject:identifier])
			{
				[module setEnabled:NO];
			}
		}
	}
	
	[self _setInitialAudioDevices];
	
	if([videoManager inputDevices] != nil)
	{
		[self _setInitialVideoInputDevice:nil];
	}
	else
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_setInitialVideoInputDevice:)
													 name:XMNotification_VideoManagerDidUpdateInputDeviceList
												   object:nil];
	}
	
	NSDictionary *videoManagerSettings = [userDefaults objectForKey:XMKey_PreferencesManagerVideoManagerSettings];
	if(videoManagerSettings != nil)
	{
		[videoManager setSettings:videoManagerSettings];
	}
}

- (void)dealloc
{
	[h323Accounts release];
	[sipAccounts release];
	[locations release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Synchronization Methods

- (void)synchronizeAndNotify
{	
	[self synchronize];
	
	// post the notification
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter postNotificationName:XMNotification_PreferencesManagerDidChangePreferences
														object:self
													  userInfo:nil];
	[notificationCenter postNotificationName:XMNotification_PreferencesManagerDidChangeActiveLocation
														object:self
													  userInfo:nil];
}

- (void)synchronize
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	/* storing the H.323 accounts */
	unsigned count = [h323Accounts count];
	unsigned i;
	NSMutableArray *dictArray = [[NSMutableArray alloc] initWithCapacity:count];
	for(i = 0; i < count; i++)
	{
		XMH323Account *h323Account = (XMH323Account *)[h323Accounts objectAtIndex:i];
		[dictArray addObject:[h323Account dictionaryRepresentation]];
	}
	[userDefaults setObject:dictArray forKey:XMKey_PreferencesManagerH323Accounts];
	[dictArray release];
	
	/* storing the SIP accounts */
	count = [sipAccounts count];
	dictArray = [[NSMutableArray alloc] initWithCapacity:count];
	for(i = 0; i < count; i++)
	{
		XMSIPAccount *sipAccount = (XMSIPAccount *)[sipAccounts objectAtIndex:i];
		[dictArray addObject:[sipAccount dictionaryRepresentation]];
	}
	[userDefaults setObject:dictArray forKey:XMKey_PreferencesManagerSIPAccounts];
	[dictArray release];
	
	/* storing the locations */
	count = [locations count];
	dictArray = [[NSMutableArray alloc] initWithCapacity:count];
	for(i = 0; i < count; i++)
	{
		XMLocation *location = (XMLocation *)[locations objectAtIndex:i];
		[dictArray addObject:[location dictionaryRepresentationWithH323Accounts:h323Accounts sipAccounts:sipAccounts]];
	}
	[userDefaults setObject:dictArray forKey:XMKey_PreferencesManagerLocations];
	[dictArray release];
	
	// increasing the integer by one since NSUserDefaults returns zero if the
	// key isn't found in preferences
	[userDefaults setInteger:(activeLocation+1) forKey:XMKey_PreferencesManagerActiveLocation];
	
	// synchronize the database
	[userDefaults synchronize];
}

#pragma mark -
#pragma mark Accessor Methods

- (unsigned)h323AccountCount
{
	return [h323Accounts count];
}

- (XMH323Account *)h323AccountAtIndex:(unsigned)index
{
	return (XMH323Account *)[h323Accounts objectAtIndex:index];
}

- (XMH323Account *)h323AccountWithTag:(unsigned)tag
{
	unsigned count = [h323Accounts count];
	unsigned i;
	
	for(i = 0; i < count; i++)
	{
		XMH323Account *h323Account = (XMH323Account *)[h323Accounts objectAtIndex:i];
		if([h323Account tag] == tag)
		{
			return h323Account;
		}
	}
	
	return nil;
}

- (NSArray *)h323Accounts
{
	unsigned count = [h323Accounts count];
	unsigned i;
	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:count];
	
	for(i = 0; i < count; i++)
	{
		[arr addObject:[[h323Accounts objectAtIndex:i] copy]];
	}
	
	return arr;
}

- (void)setH323Accounts:(NSArray *)accounts
{
	unsigned count = [accounts count];
	unsigned i;
	
	if(accounts == nil)
	{
		return;
	}
		
	[h323Accounts removeAllObjects];
	
	Class h323AccountClass = [XMH323Account class];
	
	for(i = 0; i < count; i++)
	{
		XMH323Account *h323Account = (XMH323Account *)[accounts objectAtIndex:i];
		
		if([h323Account isKindOfClass:h323AccountClass])
		{
			[h323Account savePassword];
			[h323Account clearPassword];
			
			[h323Accounts addObject:[h323Account copy]];
		}
	}
}

- (unsigned)sipAccountCount
{
	return [sipAccounts count];
}

- (XMSIPAccount *)sipAccountAtIndex:(unsigned)index
{
	return (XMSIPAccount *)[sipAccounts objectAtIndex:index];
}

- (XMSIPAccount *)sipAccountWithTag:(unsigned)tag
{
	unsigned count = [sipAccounts count];
	unsigned i;
	
	for(i = 0; i < count; i++)
	{
		XMSIPAccount *sipAccount = (XMSIPAccount *)[sipAccounts objectAtIndex:i];
		if([sipAccount tag] == tag)
		{
			return sipAccount;
		}
	}
	
	return nil;
}

- (NSArray *)sipAccounts
{
	unsigned count = [sipAccounts count];
	unsigned i;
	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:count];
	
	for(i = 0; i < count; i++)
	{
		[arr addObject:[[sipAccounts objectAtIndex:i] copy]];
	}
	
	return arr;
}

- (void)setSIPAccounts:(NSArray *)accounts
{
	unsigned count = [accounts count];
	unsigned i;
	
	if(accounts == nil)
	{
		return;
	}
	
	[sipAccounts removeAllObjects];
	
	Class sipAccountClass = [XMSIPAccount class];
	
	for(i = 0; i < count; i++)
	{
		XMSIPAccount *sipAccount = (XMSIPAccount *)[accounts objectAtIndex:i];
		
		if([sipAccount isKindOfClass:sipAccountClass])
		{
			[sipAccount savePassword];
			[sipAccount clearPassword];
			
			[sipAccounts addObject:[sipAccount copy]];
		}
	}
}

- (NSArray *)locations
{
	unsigned count = [locations count];
	unsigned i;
	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:count];
	
	for(i = 0; i < count; i++)
	{
		[arr addObject:[[locations objectAtIndex:i] copy]];
	}
	
	return arr;
}

- (void)setLocations:(NSArray *)newLocations
{
	unsigned count = [newLocations count];
	unsigned i;
	
	unsigned currentTag = [(XMLocation *)[locations objectAtIndex:activeLocation] tag];
	
	if(count != 0)
	{
		[locations removeAllObjects];
		activeLocation = 0;
	}
	
	// we have also to determine the index of the actual location since this could have changed
	for(i = 0; i < count; i++)
	{
		XMLocation *location = (XMLocation *)[newLocations objectAtIndex:i];
		
		if([location isKindOfClass:[XMLocation class]])
		{
			[locations addObject:[location copy]];
			if([location tag] == currentTag)
			{
				activeLocation = i;
			}
		}
	}
	
	XMCallManager *callManager = [XMCallManager sharedInstance];
	
	if([callManager doesAllowModifications])
	{
		XMLocation *location = (XMLocation *)[locations objectAtIndex:activeLocation];
		[location storeAccountInformationsInSubsystem];
		[callManager setActivePreferences:location];
	}
	else
	{
		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		
		[notificationCenter addObserver:self selector:@selector(_updateCallManagerPreferences:)
								   name:XMNotification_CallManagerDidClearCall object:nil];
		[notificationCenter addObserver:self selector:@selector(_updateCallManagerPreferences:)
								   name:XMNotification_CallManagerDidEndSubsystemSetup object:nil];
	}
}

- (NSArray *)locationNames
{
	unsigned count = [locations count];
	unsigned i;
	NSMutableArray *arr = [[[NSMutableArray alloc] initWithCapacity:count] autorelease];
	
	for(i = 0; i < count; i++)
	{
		[arr addObject:[(XMLocation *)[locations objectAtIndex:i] name]];
	}
	
	return arr;
}

- (unsigned)locationCount
{
	return [locations count];
}

- (XMLocation *)activeLocation
{
	if(activeLocation == -1)
	{
		return nil;
	}
	return [locations objectAtIndex:activeLocation];
}

- (unsigned)indexOfActiveLocation
{
	return activeLocation;
}

- (void)activateLocationAtIndex:(unsigned)index
{
	if(activeLocation != index && index < [locations count])
	{
		activeLocation = index;
	
		// post the notification
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_PreferencesManagerDidChangeActiveLocation
															object:self
														  userInfo:nil];
	
		XMCallManager *callManager = [XMCallManager sharedInstance];
		if([callManager doesAllowModifications])
		{
			XMLocation *location = (XMLocation *)[locations objectAtIndex:activeLocation];
			[location storeAccountInformationsInSubsystem];
			[callManager setActivePreferences:location];
		}
		else
		{
			NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
			
			[notificationCenter addObserver:self selector:@selector(_updateCallManagerPreferences:)
									   name:XMNotification_CallManagerDidClearCall object:nil];
			[notificationCenter addObserver:self selector:@selector(_updateCallManagerPreferences:)
									   name:XMNotification_CallManagerDidEndSubsystemSetup object:nil];
		}
	}
}

- (NSString *)userName
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:XMKey_PreferencesManagerUserName];
}

- (void)setUserName:(NSString *)name
{
	[[NSUserDefaults standardUserDefaults] setObject:name forKey:XMKey_PreferencesManagerUserName];
}

- (BOOL)automaticallyAcceptIncomingCalls
{
	return automaticallyAcceptIncomingCalls;
}

- (void)setAutomaticallyAcceptIncomingCalls:(BOOL)flag
{
	automaticallyAcceptIncomingCalls = flag;
}

- (BOOL)defaultAutomaticallyAcceptIncomingCalls
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:XMKey_PreferencesManagerAutomaticallyAcceptIncomingCalls];
}

- (void)setDefaultAutomaticallyAcceptIncomingCalls:(BOOL)flag
{
	[[NSUserDefaults standardUserDefaults] setBool:flag forKey:XMKey_PreferencesManagerAutomaticallyAcceptIncomingCalls];
	automaticallyAcceptIncomingCalls = flag;
}

- (BOOL)automaticallyEnterFullScreen
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:XMKey_PreferencesManagerAutomaticallyEnterFullScreen];
}

- (void)setAutomaticallyEnterFullScreen:(BOOL)flag
{
	[[NSUserDefaults standardUserDefaults] setBool:flag forKey:XMKey_PreferencesManagerAutomaticallyEnterFullScreen];
}

- (BOOL)showSelfViewMirrored
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:XMKey_PreferencesManagerShowSelfViewMirrored];
}

- (void)setShowSelfViewMirrored:(BOOL)flag
{
	[[NSUserDefaults standardUserDefaults] setBool:flag forKey:XMKey_PreferencesManagerShowSelfViewMirrored];
}

- (BOOL)automaticallyHideInCallControls
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:XMKey_PreferencesManagerAutomaticallyHideInCallControls];
}

- (void)setAutomaticallyHideInCallControls:(BOOL)flag
{
	[[NSUserDefaults standardUserDefaults] setBool:flag forKey:XMKey_PreferencesManagerAutomaticallyHideInCallControls];
}

- (XMInCallControlHideAndShowEffect)inCallControlHideAndShowEffect
{
	return (XMInCallControlHideAndShowEffect)[[NSUserDefaults standardUserDefaults] integerForKey:XMKey_PreferencesManagerInCallControlHideAndShowEffect];
}

- (void)setInCallControlHideAndShowEffect:(XMInCallControlHideAndShowEffect)effect
{
	[[NSUserDefaults standardUserDefaults] setInteger:(int)effect forKey:XMKey_PreferencesManagerInCallControlHideAndShowEffect];
}

- (BOOL)alertIncomingCalls
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:XMKey_PreferencesManagerAlertIncomingCalls];
}

- (void)setAlertIncomingCalls:(BOOL)flag
{
	[[NSUserDefaults standardUserDefaults] setBool:flag forKey:XMKey_PreferencesManagerAlertIncomingCalls];
}

- (XMIncomingCallAlertType)incomingCallAlertType
{
	return (XMIncomingCallAlertType)[[NSUserDefaults standardUserDefaults] integerForKey:XMKey_PreferencesManagerIncomingCallAlertType];
}

- (void)setIncomingCallAlertType:(XMIncomingCallAlertType)alertType
{
	[[NSUserDefaults standardUserDefaults] setInteger:(int)alertType forKey:XMKey_PreferencesManagerIncomingCallAlertType];
}

- (NSString *)passwordForServiceName:(NSString *)serviceName accountName:(NSString *)accountName
{
	OSStatus err = noErr;
	UInt32 passwordLength;
	const char *passwordString;
	
	if(serviceName == nil || accountName == nil)
	{
		return nil;
	}
	
	UInt32 serviceNameLength = [serviceName length];
	const char *serviceNameString = [serviceName cStringUsingEncoding:NSUTF8StringEncoding];
	
	UInt32 accountNameLength = [accountName length];
	const char *accountNameString = [accountName cStringUsingEncoding:NSUTF8StringEncoding];
	
	err = SecKeychainFindGenericPassword(NULL,
										 serviceNameLength,
										 serviceNameString,
										 accountNameLength,
										 accountNameString,
										 &passwordLength,
										 (void **)&passwordString,
										 NULL);
	
	if(err != noErr)
	{
		//NSLog(@"SecKeychainFindGenericPassword failed: %d", (int)err);
		return nil;
	}
	
	NSString *pwd = [[[NSString alloc] initWithBytes:passwordString length:passwordLength encoding:NSUTF8StringEncoding] autorelease];
	
	err = SecKeychainItemFreeContent(NULL, (void *)passwordString);
	
	if(err != noErr)
	{
		NSLog(@"SecKeychainItemFreeContent failed: %d", (int)err);
	}
	
	return pwd;
}

- (void)setPassword:(NSString *)password forServiceName:(NSString *)serviceName accountName:(NSString *)accountName
{
	OSStatus err = noErr;
	
	UInt32 passwordLength;
	const char *passwordString;
	SecKeychainItemRef keychainItem;
	
	if(serviceName == nil || accountName == nil)
	{
		return;
	}
	
	UInt32 serviceNameLength = [serviceName length];
	const char *serviceNameString = [serviceName cStringUsingEncoding:NSUTF8StringEncoding];
	
	UInt32 accountNameLength = [accountName length];
	const char *accountNameString = [accountName cStringUsingEncoding:NSUTF8StringEncoding];
	
	UInt32 newPasswordLength = 0;
	const char *newPasswordString = NULL;
	
	if(password != nil)
	{
		newPasswordLength = [password length];
		newPasswordString = [password cStringUsingEncoding:NSUTF8StringEncoding];
	}
	
	// first, obtain the current password file (if any)
	err = SecKeychainFindGenericPassword(NULL,
										 serviceNameLength,
										 serviceNameString,
										 accountNameLength,
										 accountNameString,
										 &passwordLength,
										 (void **)&passwordString,
										 &keychainItem);
	if(err == noErr)
	{
		if(newPasswordString == NULL)
		{
			// no password set, deleting the existing record
			err = SecKeychainItemDelete(keychainItem);
			if(err != noErr)
			{
				NSLog(@"SecKeychainItemDelete failed %d", (int)err);
			}
		}
		else if(strcmp(passwordString, newPasswordString) == 0)
		{
			// no need to modify pwd
			//NSLog(@"old pwd equal new pwd");
		}
		else
		{
			// change the password
			err = SecKeychainItemModifyAttributesAndData(keychainItem,
														 NULL,
														 newPasswordLength,
														 newPasswordString);
			if(err != noErr)
			{
				NSLog(@"SecKeychainItemModifyAttributesAndData failed: %d", (int)err);
			}
		}
		
		return;
	}
	
	// If we get here, the keychain has not yet stored a password for the service name and
	// account specified
	
	if(newPasswordString == NULL)
	{
		return;
	}
	
	// no record existing yet, thus adding a new one
	err = SecKeychainAddGenericPassword(NULL,
										serviceNameLength,
										serviceNameString,
										accountNameLength,
										accountNameString,
										newPasswordLength,
										(void *)newPasswordString,
										NULL);
	if(err != noErr)
	{
		NSLog(@"SecKeychainAddGenericPassword failed: %d", (int)err);
	}
}

- (NSString *)preferredAudioOutputDevice
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:XMKey_PreferencesManagerPreferredAudioOutputDevice];
}

- (void)setPreferredAudioOutputDevice:(NSString *)device
{
	if(device == nil)
	{
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:XMKey_PreferencesManagerPreferredAudioOutputDevice];
	}
	else
	{
		[[NSUserDefaults standardUserDefaults] setObject:device forKey:XMKey_PreferencesManagerPreferredAudioOutputDevice];
	}
}

- (NSString *)preferredAudioInputDevice
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:XMKey_PreferencesManagerPreferredAudioInputDevice];
}

- (void)setPreferredAudioInputDevice:(NSString *)device
{
	if(device == nil)
	{
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:XMKey_PreferencesManagerPreferredAudioInputDevice];
	}
	else
	{
		[[NSUserDefaults standardUserDefaults] setObject:device forKey:XMKey_PreferencesManagerPreferredAudioInputDevice];
	}
}

- (NSArray *)disabledVideoModules
{
	NSArray *disabledVideoModules = [[NSUserDefaults standardUserDefaults] arrayForKey:XMKey_PreferencesManagerDisabledVideoModules];
	
	if(disabledVideoModules == nil)
	{
		return [NSArray array];
	}
	
	return disabledVideoModules;
}

- (void)setDisabledVideoModules:(NSArray *)disabledVideoModules
{
	XMVideoManager *videoManager = [XMVideoManager sharedInstance];
	
	if(disabledVideoModules == nil)
	{
		disabledVideoModules = [NSArray array];
	}
	
	unsigned i;
	unsigned count = [videoManager videoModuleCount];
	
	for(i = 0; i < count; i++)
	{
		id<XMVideoModule> module = [videoManager videoModuleAtIndex:i];
		
		NSString *identifier = [module identifier];
		
		if([disabledVideoModules containsObject:identifier])
		{
			[module setEnabled:NO];
		}
		else
		{
			[module setEnabled:YES];
		}
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:disabledVideoModules forKey:XMKey_PreferencesManagerDisabledVideoModules];
}

- (NSString *)preferredVideoInputDevice
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:XMKey_PreferencesManagerPreferredVideoInputDevice];
}

- (void)setPreferredVideoInputDevice:(NSString *)device
{
	if(device == nil)
	{
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:XMKey_PreferencesManagerPreferredVideoInputDevice];
	}
	else
	{
		[[NSUserDefaults standardUserDefaults] setObject:device forKey:XMKey_PreferencesManagerPreferredVideoInputDevice];
	}
}

- (void)storeVideoManagerSettings
{
	XMVideoManager *videoManager = [XMVideoManager sharedInstance];
	NSDictionary *videoManagerSettings = [videoManager settings];
	[[NSUserDefaults standardUserDefaults] setObject:videoManagerSettings forKey:XMKey_PreferencesManagerVideoManagerSettings];
}

- (BOOL)searchAddressBookDatabase
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:XMKey_PreferencesManagerSearchAddressBookDatabase];
}

- (void)setSearchAddressBookDatabase:(BOOL)flag
{
	[[NSUserDefaults standardUserDefaults] setBool:flag forKey:XMKey_PreferencesManagerSearchAddressBookDatabase];
}

- (BOOL)enableAddressBookPhoneNumbers
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:XMKey_PreferencesManagerEnableAddressBookPhoneNumbers];
}

- (void)setEnableAddressBookPhoneNumbers:(BOOL)flag
{
	[[NSUserDefaults standardUserDefaults] setBool:flag forKey:XMKey_PreferencesManagerEnableAddressBookPhoneNumbers];
}

- (XMCallProtocol)addressBookPhoneNumberProtocol
{
	return (XMCallProtocol)[[NSUserDefaults standardUserDefaults] integerForKey:XMKey_PreferencesManagerAddressBookPhoneNumberProtocol];
}

- (void)setAddressBookPhoneNumberProtocol:(XMCallProtocol)callProtocol
{
	[[NSUserDefaults standardUserDefaults] setInteger:(int)callProtocol forKey:XMKey_PreferencesManagerAddressBookPhoneNumberProtocol];
}

#pragma mark -
#pragma mark Private Methods

- (void)_setInitialAudioDevices
{
	NSString *preferredInputDevice = [self preferredAudioInputDevice];
	NSString *preferredOutputDevice = [self preferredAudioOutputDevice];
	
	XMAudioManager *audioManager = [XMAudioManager sharedInstance];
	
	if(preferredInputDevice != nil)
	{
		NSArray *inputDevices = [audioManager inputDevices];
		if([inputDevices containsObject:preferredInputDevice])
		{
			[audioManager setSelectedInputDevice:preferredInputDevice];
		}
	}
	if(preferredOutputDevice != nil)
	{
		NSArray *outputDevices = [audioManager outputDevices];
		if([outputDevices containsObject:preferredOutputDevice])
		{
			[audioManager setSelectedOutputDevice:preferredOutputDevice];
		}
	}
}

- (void)_setInitialVideoInputDevice:(NSNotification *)notif
{
	XMVideoManager *videoManager = [XMVideoManager sharedInstance];
	NSArray *devices = [videoManager inputDevices];
	
	NSString *device = [self preferredVideoInputDevice];
	
	if(device == nil)
	{
		device = [devices objectAtIndex:0];
	}
	else
	{
		if(![devices containsObject:device])
		{
			device = [devices objectAtIndex:0];
		}
	}
	
	[videoManager setSelectedInputDevice:device];
	
	if(notif != nil)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:XMNotification_VideoManagerDidUpdateInputDeviceList object:nil];
	}
}

- (void)_updateCallManagerPreferences:(NSNotification *)notif
{
	XMCallManager *callManager = [XMCallManager sharedInstance];
	
	if([callManager doesAllowModifications])
	{
		XMLocation *location = (XMLocation *)[locations objectAtIndex:activeLocation];
		[location storeAccountInformationsInSubsystem];
		[callManager setActivePreferences:location];
		
		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		
		[notificationCenter removeObserver:self name:XMNotification_CallManagerDidEndSubsystemSetup object:nil];
		[notificationCenter removeObserver:self name:XMNotification_CallManagerDidClearCall object:nil];
	}
}

@end
