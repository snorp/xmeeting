/*
 * $Id: XMCallAddressManager.m,v 1.3 2005/06/23 12:35:56 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMCallAddressManager.h"

@interface XMCallAddressManager (PrivateMethods)

- (id)_init;

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
	
	return self;
}

- (void)dealloc
{
	[callAddressProviders release];
	
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

- (id<XMCallAddress>)activeCallAddress
{
	return activeCallAddress;
}

- (BOOL)makeCallToAddress:(id<XMCallAddress>)callAddress
{
	[activeCallAddress release];
	activeCallAddress = [callAddress retain];
	
	NSLog(@"calling");
	XMCallInfo *callInfo = [[XMCallManager sharedInstance] callURL:[callAddress url]];
	if(callInfo != nil)
	{
		NSLog(@"succesful");
		return YES;
	}
	NSLog(@"failed");
	return NO;
}

@end
