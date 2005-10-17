/*
 * $Id: XMPreferencesManager.m,v 1.6 2005/10/17 17:00:27 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMPreferencesManager.h"
#import "XMLocation.h"

NSString *XMNotification_PreferencesDidChange = @"XMeeting_PreferencesDidChange";
NSString *XMNotification_ActiveLocationDidChange = @"XMeeting_ActiveLocationDidChange";

NSString *XMKey_Locations = @"XMeeting_Locations";
NSString *XMKey_ActiveLocation = @"XMeeting_ActiveLocation";
NSString *XMKey_AutomaticallyAcceptIncomingCalls = @"XMeeting_AutomaticallyAcceptIncomingCalls";
NSString *XMKey_UserName = @"XMeeting_UserName";

@interface XMPreferencesManager (PrivateMethods)

- (id)_init;
- (void)_setup;
- (void)_writeLocationsToUserDefaults;

@end

@implementation XMPreferencesManager

#pragma mark Init & Deallocation Methods

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
	activeLocation = [userDefaults integerForKey:XMKey_ActiveLocation] - 1;
	
	if(activeLocation == -1 && [locations count] != 0)
	{
		// in this case, we automatically use the first location found
		activeLocation = 0;
	}
	
	automaticallyAcceptIncomingCalls = [userDefaults boolForKey:XMKey_AutomaticallyAcceptIncomingCalls];
	
	[[XMCallManager sharedInstance] setActivePreferences:[locations objectAtIndex:activeLocation]];
}

- (void)dealloc
{
	[locations release];
	
	[super dealloc];
}

#pragma mark Getting & Setting Methods

- (void)synchronizeAndNotify
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[userDefaults setInteger:activeLocation forKey:XMKey_ActiveLocation];
	
	[self _writeLocationsToUserDefaults];
	
	// synchronize the database
	[userDefaults synchronize];
		
	// post the notification
	[notificationCenter postNotificationName:XMNotification_PreferencesDidChange
														object:self
													  userInfo:nil];
	[notificationCenter postNotificationName:XMNotification_ActiveLocationDidChange
														object:self
													  userInfo:nil];
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
	
	if(count == 0)
	{
		// this isn't allowed and we simply return
		return;
	}
	
	unsigned i;
	unsigned currentTag = [(XMLocation *)[locations objectAtIndex:activeLocation] _tag];
	
	// this is safe since locations is an internal variable and is never
	// directly exposed to the outside
	[locations removeAllObjects];
	
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
	
	[[XMCallManager sharedInstance] setActivePreferences:[locations objectAtIndex:activeLocation]];
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
	
		[[XMCallManager sharedInstance] setActivePreferences:[locations objectAtIndex:activeLocation]];
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

#pragma mark Private Methods

- (void)_writeLocationsToUserDefaults
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
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
}

@end
