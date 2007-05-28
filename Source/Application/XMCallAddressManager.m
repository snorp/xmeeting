/*
 * $Id: XMCallAddressManager.m,v 1.10 2007/05/28 09:56:04 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMCallAddressManager.h"

@interface XMCallAddressManager (PrivateMethods)

- (id)_init;

- (void)_callEnded:(NSNotification *)notif;

@end

@implementation XMCallAddressManager

#pragma mark Class Methods

+ (XMCallAddressManager *)sharedInstance
{
	static XMCallAddressManager *sharedInstance = nil;
	
	if(sharedInstance == nil)
	{
		sharedInstance = [[XMCallAddressManager alloc] _init];
	}
	return sharedInstance;
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
	callAddressProviders = [[NSMutableArray alloc] initWithCapacity:3];
	activeCallAddress = nil;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_callEnded:)
												 name:XMNotification_CallManagerDidNotStartCalling
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_callEnded:)
												 name:XMNotification_CallManagerDidClearCall
											   object:nil];	
	return self;
}

- (void)dealloc
{
	[callAddressProviders release];
	
	if(activeCallAddress != nil)
	{
		[activeCallAddress release];
		activeCallAddress = nil;
	}
	
	[super dealloc];
}

#pragma mark handling CallAddressProviders

- (void)addCallAddressProvider:(id<XMCallAddressProvider>)provider
{
	[callAddressProviders addObject:provider];
}

- (void)removeCallAddressProvider:(id<XMCallAddressProvider>)provider
{
	[callAddressProviders removeObject:provider];
}

#pragma mark handling call addresses

- (NSArray *)addressesMatchingString:(NSString *)searchString
{
	unsigned i;
	unsigned count = [callAddressProviders count];
	
	NSMutableArray *matches = [NSMutableArray arrayWithCapacity:10];
	
	for(i = 0; i < count; i++)
	{
		id<XMCallAddressProvider> provider = (id<XMCallAddressProvider>)[callAddressProviders objectAtIndex:i];
		NSArray *providerMatches = [provider addressesMatchingString:searchString];
		
		[matches addObjectsFromArray:providerMatches];
	}
	
	return matches;
}

- (NSString *)completionStringForAddress:(id<XMCallAddress>)address uncompletedString:(NSString *)uncompletedString
{
	id<XMCallAddressProvider> provider = [address provider];
	
	if(provider == nil)
	{
		return nil;
	}
	return [provider completionStringForAddress:address uncompletedString:uncompletedString];
}

- (id<XMCallAddress>)addressMatchingResource:(XMAddressResource *)addressResource
{
    unsigned i;
    unsigned count = [callAddressProviders count];
    
    for (i = 0; i < count; i++) 
    {
        id<XMCallAddressProvider> provider = (id<XMCallAddressProvider>)[callAddressProviders objectAtIndex:i];
        id<XMCallAddress> address = [provider addressMatchingResource:addressResource];
        if (address != nil) {
            return address;
        }
    }
    return nil;
}

- (NSArray *)alternativesForAddress:(id<XMCallAddress>)address selectedIndex:(unsigned *)selectedIndex
{
	id<XMCallAddressProvider> provider = [address provider];
	
	if(provider == nil)
	{
		return [NSArray array];
	}
	return [provider alternativesForAddress:address selectedIndex:selectedIndex];
}

- (id<XMCallAddress>)alternativeForAddress:(id<XMCallAddress>)address atIndex:(unsigned)index
{
	id<XMCallAddressProvider> provider = [address provider];
	
	if(provider == nil)
	{
		return nil;
	}
	
	return [provider alternativeForAddress:address atIndex:index];
}

- (NSArray *)allAddresses
{
	unsigned i;
	unsigned count = [callAddressProviders count];
	
	NSMutableArray *addresses = [NSMutableArray arrayWithCapacity:20];
	
	for(i = 0; i < count; i++)
	{
		id<XMCallAddressProvider> provider = (id<XMCallAddressProvider>)[callAddressProviders objectAtIndex:i];
		NSArray *addr = [provider allAddresses];
		
		[addresses addObjectsFromArray:addr];
	}
	
	return addresses;
}

- (id<XMCallAddress>)activeCallAddress
{
	return activeCallAddress;
}

- (void)makeCallToAddress:(id<XMCallAddress>)callAddress
{
	if(activeCallAddress != nil)
	{
		NSLog(@"Illegal, active callAddress not nil");
		return;
	}
	
	if(callAddress == nil ||
	   [[[callAddress addressResource] address] isEqualToString:@""])
	{
		NSLog(@"nil or EMPTY ADDRESS!");
		return;
	}
	
	activeCallAddress = [callAddress retain];

	[[XMCallManager sharedInstance] makeCall:[callAddress addressResource]];
}

#pragma mark Private Methods

- (void)_callEnded:(NSNotification *)notif
{
	if(activeCallAddress != nil)
	{
		[activeCallAddress release];
		activeCallAddress = nil;
	}
}

@end
