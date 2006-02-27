/*
 * $Id: XMPreferencesManager.m,v 1.12 2006/02/27 16:11:39 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMPreferencesManager.h"
#import "XMLocation.h"

NSString *XMNotification_PreferencesDidChange = @"XMeeting_PreferencesDidChange";
NSString *XMNotification_ActiveLocationDidChange = @"XMeeting_ActiveLocationDidChange";

NSString *XMKey_PreferencesAvailable = @"XMeeting_PreferencesAvailable";
NSString *XMKey_Locations = @"XMeeting_Locations";
NSString *XMKey_ActiveLocation = @"XMeeting_ActiveLocation";
NSString *XMKey_AutomaticallyAcceptIncomingCalls = @"XMeeting_AutomaticallyAcceptIncomingCalls";
NSString *XMKey_UserName = @"XMeeting_UserName";
NSString *XMKey_DisabledVideoModules = @"XMeeting_DisabledVideoModules";
NSString *XMKey_PreferredVideoInputDevice = @"XMeeting_PreferredVideoInputDevice";

@interface XMPreferencesManager (PrivateMethods)

- (id)_init;
- (void)_setup;

- (NSString *)_passwordForServiceName:(NSString *)serviceName accountName:(NSString *)accountName;
- (void)_setPassword:(NSString *)password forServiceName:(NSString *)serviceName accountName:(NSString *)accountName;

- (void)_setInitialVideoInputDevice:(NSNotification *)notif;

- (void)_updateCallManagerPreferences:(NSNotification *)notif;

@end

@interface XMPasswordRecord : NSObject {

	NSString *serviceName;
	NSString *accountName;
	NSString *password;

}

- (id)_initWithServiceName:(NSString *)serviceName accountName:(NSString *)accountName password:(NSString *)password;

- (NSString *)_serviceName;
- (NSString *)_accountName;
- (NSString *)_password;
- (void)_setPassword:(NSString *)password;

@end

@implementation XMPreferencesManager

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
	
	BOOL doesHavePreferences = [userDefaults boolForKey:XMKey_PreferencesAvailable];
	
	// this is a one-time check, thus next time we return YES
	[userDefaults setBool:YES forKey:XMKey_PreferencesAvailable];
	
	return doesHavePreferences;
}

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
	
	return self;
}

- (void)_setup
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	/* Register the default values of the preferences */
	NSMutableDictionary *defaultsDict = [[NSMutableDictionary alloc] init];
	
	/* intermediate code to make sure that at least one location is present in UserDefaults */
	/* later, this will be replaced by some sort of wizard popping up */
	XMLocation *defaultLocation = [[XMLocation alloc] initWithName:NSLocalizedString(@"<Default Location>", @"")];
	NSDictionary *dict = [defaultLocation dictionaryRepresentation];
	NSArray *defaultLocationArray = [NSArray arrayWithObject:dict];
	[defaultsDict setObject:defaultLocationArray forKey:XMKey_Locations];
	[defaultLocation release];
	
	[defaultsDict setObject:NSFullUserName() forKey:XMKey_UserName];
	
	NSNumber *number = [[NSNumber alloc] initWithBool:NO];
	[defaultsDict setObject:number forKey:XMKey_AutomaticallyAcceptIncomingCalls];
	[number release];
	
	NSArray *initialDisabledVideoModules = [[NSArray alloc] initWithObjects:@"XMScreenVideoInputModule", nil];
	[defaultsDict setObject:initialDisabledVideoModules forKey:XMKey_DisabledVideoModules];
	[initialDisabledVideoModules release];
	
	// code to be written yet
	[userDefaults registerDefaults:defaultsDict];
	[defaultsDict release];
	
	/* getting the locations list from UserDefaults */
	locations = [[NSMutableArray alloc] initWithCapacity:1];
	NSArray *dictArray = (NSArray *)[userDefaults objectForKey:XMKey_Locations];
	if(dictArray)
	{
		unsigned count = [dictArray count];
		unsigned i;
		
		for(i = 0; i < count; i++)
		{
			NSDictionary *dict = (NSDictionary *)[dictArray objectAtIndex:i];
			XMLocation *location = [[XMLocation alloc] initWithDictionary:dict];
			[location _updateTag];
			[locations addObject:location];
			[location release];
		}
	}
	
	// since NSUserDefaults returns 0 if no value for the Key is found, we
	// simply increase the stored value by one;
	int index = [userDefaults integerForKey:XMKey_ActiveLocation];
	if(index == 0)
	{
		activeLocation = 0;
	}
	else
	{
		activeLocation = (unsigned)(index-1);
	}
	
	automaticallyAcceptIncomingCalls = [userDefaults boolForKey:XMKey_AutomaticallyAcceptIncomingCalls];
	
	gatekeeperPasswords = [[NSMutableArray alloc] initWithCapacity:3];
	temporaryGatekeeperPasswords = nil;
	
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
}

- (void)dealloc
{
	[locations release];
	
	[gatekeeperPasswords release];
	if(temporaryGatekeeperPasswords != nil)
	{
		[temporaryGatekeeperPasswords release];
	}
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

#pragma mark Getting & Setting Methods

- (void)synchronizeAndNotify
{		
	[self synchronize];
	
	// post the notification
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter postNotificationName:XMNotification_PreferencesDidChange
														object:self
													  userInfo:nil];
	[notificationCenter postNotificationName:XMNotification_ActiveLocationDidChange
														object:self
													  userInfo:nil];
}

- (void)synchronize
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

	// increasing the integer by one since NSUserDefaults returns zero if the
	// key isn't found in preferences
	[userDefaults setInteger:(activeLocation+1) forKey:XMKey_ActiveLocation];
	unsigned count = [locations count];
	unsigned i;
	NSMutableArray *dictArray = [[NSMutableArray alloc] initWithCapacity:count];
	for(i = 0; i < count; i++)
	{
		XMLocation *location = (XMLocation *)[locations objectAtIndex:i];
		[dictArray addObject:[location dictionaryRepresentation]];
	}
	
	[userDefaults setObject:dictArray forKey:XMKey_Locations];
	[dictArray release];
	
	// synchronize the database
	[userDefaults synchronize];
}

- (NSArray *)locations
{
	unsigned count = [locations count];
	unsigned i;
	NSMutableArray *arr = [[[NSMutableArray alloc] initWithCapacity:count] autorelease];
	
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
	unsigned currentTag = [(XMLocation *)[locations objectAtIndex:activeLocation] _tag];
	
	if(count != 0)
	{
		[locations removeAllObjects];
	}
	
	// we have also to determine the index of the actual location since this could have changed
	activeLocation = 0;
	for(i = 0; i < count; i++)
	{
		XMLocation *location = (XMLocation *)[newLocations objectAtIndex:i];
		
		if([location isKindOfClass:[XMLocation class]])
		{
			[locations addObject:[location copy]];
			if([location _tag] == currentTag)
			{
				activeLocation = i;
			}
		}
	}
	
	XMCallManager *callManager = [XMCallManager sharedInstance];
	
	if([callManager doesAllowModifications])
	{
		[callManager setActivePreferences:[locations objectAtIndex:activeLocation]];
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
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_ActiveLocationDidChange
															object:self
														  userInfo:nil];
	
		XMCallManager *callManager = [XMCallManager sharedInstance];
		if([callManager doesAllowModifications])
		{
			[callManager setActivePreferences:[locations objectAtIndex:activeLocation]];
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
	return [[NSUserDefaults standardUserDefaults] objectForKey:XMKey_UserName];
}

- (void)setUserName:(NSString *)name
{
	[[NSUserDefaults standardUserDefaults] setObject:name forKey:XMKey_UserName];
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
	return [[NSUserDefaults standardUserDefaults] boolForKey:XMKey_AutomaticallyAcceptIncomingCalls];
}

- (void)setDefaultAutomaticallyAcceptIncomingCalls:(BOOL)flag
{
	[[NSUserDefaults standardUserDefaults] setBool:flag forKey:XMKey_AutomaticallyAcceptIncomingCalls];
	automaticallyAcceptIncomingCalls = flag;
}

- (NSString *)gatekeeperPasswordForLocation:(XMLocation *)location
{
	NSString *serviceName = [location gatekeeperAddress];
	if(serviceName == nil)
	{
		serviceName = [location gatekeeperID];
	}
	NSString *accountName = [location gatekeeperUsername];
	
	if(serviceName == nil || accountName == nil)
	{
		return nil;
	}
	
	unsigned count = [gatekeeperPasswords count];
	unsigned i;
	
	for(i = 0; i < count; i++)
	{
		XMPasswordRecord *record = (XMPasswordRecord *)[gatekeeperPasswords objectAtIndex:i];
		
		NSString *recordServiceName = [record _serviceName];
		
		if(![serviceName isEqualToString:recordServiceName])
		{
			continue;
		}
		
		NSString *recordAccountName = [record _accountName];
		if(![accountName isEqualToString:recordAccountName])
		{
			continue;
		}
		
		// both service name and account name match
		return [record _password];
	}
	
	// this record is not yet existant
	NSString *password = [self _passwordForServiceName:serviceName accountName:accountName];
	XMPasswordRecord *record = [[XMPasswordRecord alloc] _initWithServiceName:serviceName accountName:accountName password:password];
	[gatekeeperPasswords addObject:record];
	[record release];
	
	return password;
}

- (NSString *)temporaryGatekeeperPasswordForLocation:(XMLocation *)location
{
	NSString *serviceName = [location gatekeeperAddress];
	if(serviceName == nil)
	{
		serviceName = [location gatekeeperID];
	}
	NSString *accountName = [location gatekeeperUsername];
	
	if(serviceName == nil || accountName == nil)
	{
		return nil;
	}
	
	if(temporaryGatekeeperPasswords == nil)
	{
		temporaryGatekeeperPasswords = [gatekeeperPasswords mutableCopy];
	}
	
	unsigned count = [temporaryGatekeeperPasswords count];
	unsigned i;
	
	for(i = 0; i < count; i++)
	{
		XMPasswordRecord *record = (XMPasswordRecord *)[temporaryGatekeeperPasswords objectAtIndex:i];
		
		NSString *recordServiceName = [record _serviceName];
		if(![serviceName isEqualToString:recordServiceName])
		{
			continue;
		}
		
		NSString *recordAccountName = [record _accountName];
		if(![accountName isEqualToString:recordAccountName])
		{
			continue;
		}
		
		// both service name and account name match
		return [record _password];
	}
	
	// this record is not yet existant.
	NSString *password = [self _passwordForServiceName:serviceName accountName:accountName];
	XMPasswordRecord *record = [[XMPasswordRecord alloc] _initWithServiceName:serviceName accountName:accountName password:password];
	[temporaryGatekeeperPasswords addObject:record];
	[record release];
	
	return password;
}

- (void)setTemporaryGatekeeperPassword:(NSString *)password forLocation:(XMLocation *)location
{
	NSString *serviceName = [location gatekeeperAddress];
	if(serviceName == nil)
	{
		serviceName = [location gatekeeperID];
	}
	NSString *accountName = [location gatekeeperUsername];
	
	if(serviceName == nil || accountName == nil)
	{
		return;
	}
	
	if(temporaryGatekeeperPasswords == nil)
	{
		temporaryGatekeeperPasswords = [gatekeeperPasswords mutableCopy];
	}
	
	unsigned count = [temporaryGatekeeperPasswords count];
	unsigned i;
	
	for(i = 0; i < count; i++)
	{
		XMPasswordRecord *record = (XMPasswordRecord *)[temporaryGatekeeperPasswords objectAtIndex:i];
		
		NSString *recordServiceName = [record _serviceName];
		
		if(![serviceName isEqualToString:recordServiceName])
		{
			continue;
		}
		
		NSString *recordAccountName = [record _accountName];
		if(![accountName isEqualToString:recordAccountName])
		{
			continue;
		}
		
		// both service name and account name match
		[record _setPassword:password];
		return;
	}
	
	// this location has not yet set a password
	if(password != nil)
	{
		XMPasswordRecord *record = [[XMPasswordRecord alloc] _initWithServiceName:serviceName accountName:accountName password:password];
		[temporaryGatekeeperPasswords addObject:record];
		[record release];
	}
}

- (void)saveTemporaryPasswords
{
	if(temporaryGatekeeperPasswords != nil)
	{
		[gatekeeperPasswords release];
		gatekeeperPasswords = [temporaryGatekeeperPasswords mutableCopy];
		
		unsigned count = [gatekeeperPasswords count];
		unsigned i;
		
		for(i = 0; i < count; i++)
		{
			XMPasswordRecord *record = (XMPasswordRecord *)[gatekeeperPasswords objectAtIndex:i];
			
			NSString *serviceName = [record _serviceName];
			NSString *accountName = [record _accountName];
			NSString *password = [record _password];
			
			[self _setPassword:password forServiceName:serviceName accountName:accountName];
		}
	}
}

- (void)clearTemporaryPasswords
{
	if(temporaryGatekeeperPasswords != nil)
	{
		[temporaryGatekeeperPasswords release];
		temporaryGatekeeperPasswords = nil;
	}
}

- (NSArray *)disabledVideoModules
{
	NSArray *disabledVideoModules = [[NSUserDefaults standardUserDefaults] arrayForKey:XMKey_DisabledVideoModules];
	
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
	
	[[NSUserDefaults standardUserDefaults] setObject:disabledVideoModules forKey:XMKey_DisabledVideoModules];
}

- (NSString *)preferredVideoInputDevice
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:XMKey_PreferredVideoInputDevice];
}

- (void)setPreferredVideoInputDevice:(NSString *)device
{
	if(device == nil)
	{
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:XMKey_PreferredVideoInputDevice];
	}
	else
	{
		[[NSUserDefaults standardUserDefaults] setObject:device forKey:XMKey_PreferredVideoInputDevice];
	}
}

#pragma mark Private Methods

- (NSString *)_passwordForServiceName:(NSString *)serviceName accountName:(NSString *)accountName
{
	OSStatus err = noErr;
	UInt32 passwordLength;
	const char *passwordString;
	
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
		NSLog(@"SecKeychainFindGenericPassword failed: %d", (int)err);
		return nil;
	}
	
	NSString *password = [NSString stringWithCString:passwordString encoding:NSUTF8StringEncoding];
	
	err = SecKeychainItemFreeContent(NULL, (void *)passwordString);
	
	if(err != noErr)
	{
		NSLog(@"SecKeychainItemFreeContent failed: %d", (int)err);
	}
	
	return password;
}

- (void)_setPassword:(NSString *)password forServiceName:(NSString *)serviceName accountName:(NSString *)accountName
{
	OSStatus err = noErr;
	
	UInt32 passwordLength;
	const char *passwordString;
	SecKeychainItemRef keychainItem;
	
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
			NSLog(@"old pwd equal new pwd");
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
		[callManager setActivePreferences:[locations objectAtIndex:activeLocation]];
		
		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		
		[notificationCenter removeObserver:self name:XMNotification_CallManagerDidEndSubsystemSetup object:nil];
		[notificationCenter removeObserver:self name:XMNotification_CallManagerDidClearCall object:nil];
	}
}

@end

@implementation XMPasswordRecord

- (id)_initWithServiceName:(NSString *)theServiceName accountName:(NSString *)theAccountName password:(NSString *)thePassword
{
	self = [super init];
	
	if(theServiceName != nil)
	{
		serviceName = [theServiceName copy];
	}
	else
	{
		serviceName = nil;
	}
	
	if(theAccountName != nil)
	{
		accountName = [theAccountName copy];
	}
	else
	{
		accountName = nil;
	}
	
	if(thePassword != nil)
	{
		password = [thePassword copy];
	}
	
	return self;
}

- (void)dealloc
{
	if(serviceName != nil)
	{
		[serviceName release];
	}
	if(accountName != nil)
	{
		[accountName release];
	}
	if(password != nil)
	{
		[password release];
	}
	
	[super dealloc];
}

- (NSString *)_serviceName
{
	return serviceName;
}

- (NSString *)_accountName
{
	return accountName;
}

- (NSString *)_password
{
	return password;
}

- (void)_setPassword:(NSString *)thePassword
{
	NSString *old = password;
	password = [thePassword retain];
	[old release];
}

@end
