/*
 * $Id: XMPreferencesManager.m,v 1.2 2005/04/30 20:14:59 hfriederich Exp $
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

@interface XMPreferencesManager (PrivateMethods)

- (id)_init;
- (void)_writeLocationsToUserDefaults;

@end

@implementation XMPreferencesManager

+ (XMPreferencesManager *)sharedInstance
{
	static XMPreferencesManager *sharedInstance = nil;
	
	if(!sharedInstance)
	{
		sharedInstance = [[XMPreferencesManager alloc] _init];
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
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	/* Register the default values of the preferences */
	NSMutableDictionary *defaultsDict = [[NSMutableDictionary alloc] init];
	
	/* intermediate code to make sure that at least one location is present in UserDefaults */
	/* later, this will be replaced by some sort of wizard popping up */
	XMLocation *defaultLocation = [[XMLocation alloc] initWithName:@"<DefaultLocation>"];
	NSDictionary *dict = [defaultLocation dictionaryRepresentation];
	NSArray *defaultLocationArray = [NSArray arrayWithObject:dict];
	[defaultsDict setObject:defaultLocationArray forKey:XMKey_Locations];
	[defaultLocation release];
	
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
	
	return self;
}

- (void)dealloc
{
	[locations release];
	
	[super dealloc];
}

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
	unsigned i;
	
	// this is safe since locations is an internal variable and is never
	// directly exposed to the outside
	[locations removeAllObjects];
	
	for(i = 0; i < count; i++)
	{
		NSObject *obj = [newLocations objectAtIndex:i];
		
		if([obj isKindOfClass:[XMLocation class]])
		{
			[locations addObject:[obj copy]];
		}
	}
}

- (NSArray *)locationNames
{
	unsigned count = [locations count];
	unsigned i;
	NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:count];
	
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

- (void)activateLocationAtIndex:(unsigned)index
{
	if(index >= 0 && index < [locations count])
	{
		activeLocation = index;
	}
	
	// post the notification
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_ActiveLocationDidChange
														object:self
													  userInfo:nil];
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
