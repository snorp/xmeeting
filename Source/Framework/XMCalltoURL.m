/*
 * $Id: XMCalltoURL.m,v 1.3 2006/03/14 23:05:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMStringConstants.h"
#import "XMPrivate.h"

#import "XMCalltoURL.h"
#import "XMUtils.h"

NSString *XMKey_CalltoURLType = @"XMeeting_CalltoURLType";
NSString *XMKey_CalltoURLConferenceToJoin = @"XMeeting_CalltoURLConferenceToJoin";
NSString *XMKey_CalltoURLGatekeeperHost = @"XMeeting_CalltoURLGatekeeperHost";

@interface XMCalltoURL (PrivateMethods)

- (BOOL)_setAddress:(NSString *)theAddress;
- (BOOL)_setPort:(unsigned)thePort;
- (BOOL)_setConferenceToJoin:(NSString *)theConference;
- (BOOL)_parseAddressPart:(NSString *)addressPart allowPortSpecification:(BOOL)allowPortSpecification;

@end

@implementation XMCalltoURL

#pragma mark Class Methods

+ (BOOL)canHandleString:(NSString *)url
{
	return [url hasPrefix:@"callto:"];
}

+ (BOOL)canHandleDictionary:(NSDictionary *)dict
{
	NSNumber *number = (NSNumber *)[dict objectForKey:XMKey_URLType];
	
	if(number != nil && [number unsignedIntValue] == XMURLType_Callto)
	{
		return YES;
	}
	return NO;
}

+ (XMCalltoURL *)urlWithString:(NSString *)url
{
	XMCalltoURL *calltoURL = [[[XMCalltoURL alloc] initWithString:url] autorelease];
	return calltoURL;
}

+ (XMCalltoURL *)urlWithDictionary:(NSDictionary *)dict
{
	XMCalltoURL *calltoURL = [[[XMCalltoURL alloc] initWithDictionary:dict] autorelease];
	return calltoURL;
}

#pragma mark Init & Deallocation Methods

- (id)init
{
	url = nil;
	
	type = XMCalltoURLType_Unknown;
	address = nil;
	port = 0;
	conferenceToJoin = nil;
	
	gkHost = nil;
	
	return self;
}

- (id)initWithString:(NSString *)urlString
{
	[self init];
	
	NSScanner *scanner = [[NSScanner alloc] initWithString:urlString];
	NSString *scannedAddressPart;
	
	url = [urlString copy];
	
	// If string does not begin with "callto:", we have not a valid url, therefore return nil.
	// If the string equals to "callto:", there is no following address and this is threated 
	// as an error.
	if(![scanner scanString:@"callto:" intoString:nil])
	{
		[self release];
		[scanner release];
		return nil;
	}
	
	while([scanner scanString:@"/" intoString:nil]) 
	{
		/* just ignore it */
	}
	
	BOOL hasPlusPrefix = NO;
	
	// if the address is a phone number and this number starts with a +, we have to
	// take extra care to no confuse the parser	
	if([scanner scanString:@"+" intoString:nil])
	{
		hasPlusPrefix = YES;
	}
	
	if(![scanner scanUpToString:@"+" intoString:&scannedAddressPart])
	{
		// the scanner was not able to scan any characters, therefore this url is not valid
		[self release];
		[scanner release];
		return nil;
	}
	
	// from this point, the parsing is regarded to be successful since the url contains at least
	// the address part. Not parsable suffixes are just ignored. Only if the address part turns
	// out to be invalid, nil is returned.
	while(![scanner isAtEnd])
	{
		if(!gkHost) // we haven't parsed any gatekeeper server yet.
		{
			if([scanner scanString:@"+gatekeeper=" intoString:nil])
			{
				[scanner scanUpToString:@"+" intoString:&gkHost];
				continue;
			}
		}
		
		if(type == XMCalltoURLType_Unknown && [scanner scanString:@"+type=" intoString:nil])
		{
			NSString *typeString;
			
			if([scanner scanUpToString:@"+" intoString:&typeString])
			{
				if([typeString isEqualToString:@"phone"] ||
				   [typeString isEqualToString:@"host"])
				{
					type = XMCalltoURLType_Gatekeeper;
				}
				else if([typeString isEqualToString:@"ip"])
				{
					type = XMCalltoURLType_Direct;
				}
				else if([typeString isEqualToString:@"directory"])
				{
					type = XMCalltoURLType_Directory;
				}
				continue;
			}
		}
		
		if([scanner scanString:@"+gateway=" intoString:nil])
		{
			type = XMCalltoURLType_Gateway;
			continue;
		}
		
		// if we didn't parse anything, just go on to the next "+" section
		[scanner scanUpToString:@"+" intoString:nil];
	}
	
	// we have finished parsing the content
	[scanner release];
	
	if(type == XMCalltoURLType_Unknown)
	{
		// this is the default type
		type = XMCalltoURLType_Gatekeeper;
	}
	
	if(type == XMCalltoURLType_Gatekeeper || type == XMCalltoURLType_Direct)
	{
		BOOL allowPortSpecification = (type == XMCalltoURLType_Direct);
		if(![self _parseAddressPart:scannedAddressPart allowPortSpecification:allowPortSpecification])
		{
			[self release];
			return nil;
		}
	}
	else
	{
		[self _setAddress:scannedAddressPart];
	}
	
	if(hasPlusPrefix)
	{
		[self _setAddress:[NSString stringWithFormat:@"+%@", address]];
	}
	
	// finally, we have to retain the parsed strings
	[gkHost retain];
	
	return self;
}

- (id)initWithDictionary:(NSDictionary *)dictionary
{
	NSObject *object;
	
	[self init];
	
	object = [dictionary objectForKey:XMKey_URLType];
	if(!object || [(NSNumber *)object unsignedIntValue] != XMURLType_Callto)
	{
		// the dictionary does not contain an callto: url
		[self release];
		return nil;
	}
	
	object = [dictionary objectForKey:XMKey_URLString];
	if(object)
	{
		url = [object copy];
	}
	
	object = [dictionary objectForKey:XMKey_CalltoURLType];
	if(object)
	{
		type = [(NSNumber *)object unsignedIntValue];
	}
	
	object = [dictionary objectForKey:XMKey_URLAddress];
	if(object)
	{
		[self _setAddress:(NSString *)object];
	}
	
	object = [dictionary objectForKey:XMKey_URLPort];
	if(object)
	{
		[self _setPort:[(NSNumber *)object unsignedIntValue]];
	}
	
	object = [dictionary objectForKey:XMKey_CalltoURLConferenceToJoin];
	if(object)
	{
		[self _setConferenceToJoin:(NSString *)object];
	}
	
	object = [dictionary objectForKey:XMKey_CalltoURLGatekeeperHost];
	if(object)
	{
		gkHost = [object copy];
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
	[self init];
	
	if([coder allowsKeyedCoding])
	{
		url = [[coder decodeObjectForKey:XMKey_URLString] retain];
		type = [coder decodeIntForKey:XMKey_CalltoURLType];
		[self _setAddress:[coder decodeObjectForKey:XMKey_URLAddress]];
		[self _setPort:[coder decodeIntForKey:XMKey_URLPort]];
		[self _setConferenceToJoin:[coder decodeObjectForKey:XMKey_CalltoURLConferenceToJoin]];
		gkHost = [[coder decodeObjectForKey:XMKey_CalltoURLGatekeeperHost] retain];
		
	}
	else
	{
		[NSException raise:XMException_UnsupportedCoder format:XMExceptionReason_UnsupportedCoder];
		[self release];
		return nil;
	}
	
	return self;
}

- (void)dealloc
{
	[url release];
	[address release];
	[conferenceToJoin release];
	[gkHost release];
	
	[super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	if([coder allowsKeyedCoding])
	{
		[coder encodeObject:url forKey:XMKey_URLString];
		[coder encodeInt:type forKey:XMKey_CalltoURLType];
		[coder encodeObject:address forKey:XMKey_URLAddress];
		[coder encodeInt:port forKey:XMKey_URLPort];
		[coder encodeObject:conferenceToJoin forKey:XMKey_CalltoURLConferenceToJoin];
		[coder encodeObject:gkHost forKey:XMKey_CalltoURLGatekeeperHost];
	}
	else
	{
		[NSException raise:XMException_UnsupportedCoder format:@"Only NSCoder subclasses which allow keyed coding are supported."];
	}
}	

#pragma mark Obtaining String & Dictionary representations

- (NSString *)stringRepresentation
{
	if(!url)
	{
		NSMutableString *str = [[NSMutableString alloc] initWithCapacity:50];
		[str appendString:@"callto:/"];
		
		if(type == XMCalltoURLType_Direct)
		{
			NSString *addr = address;
			if(!addr)
			{
				addr = @"";
			}
			[str appendString:addr];
			
			if(port != 0)
			{
				[str appendFormat:@":%d", port];
			}
			
			if(conferenceToJoin != nil)
			{
				[str appendString:@"**"];
				[str appendString:conferenceToJoin];
			}
			[str appendString:@"+type=ip"];
		}
		else if(type == XMCalltoURLType_Gatekeeper)
		{
			NSString *addr = address;
			
			if(!addr)
			{
				addr = @"";
			}
			[str appendString:addr];
			
			if(conferenceToJoin != nil)
			{
				[str appendString:@"**"];
				[str appendString:conferenceToJoin];
			}
			
			if([XMUtils isPhoneNumber:addr])
			{
				[str appendString:@"+type=phone"];
			}
			else
			{
				[str appendString:@"+type=host"];
			}
			
			if(gkHost != nil)
			{
				[str appendString:@"+gatekeeper="];
				[str appendString:gkHost];
			}
		}
		else if(type == XMCalltoURLType_Directory)
		{
			NSString *addr = address;
			
			if(!addr)
			{
				addr = @"";
			}
			[str appendString:addr];
			[str appendString:@"+type=directory"];
		}
		else if(type == XMCalltoURLType_Gateway)
		{
			NSString *addr = address;
			
			if(!addr)
			{
				addr = @"";
			}
			[str appendString:addr];
			[str appendString:@"+type=gateway"];
		}
		
		url = [str copy];
		[str release];
	}
	
	return url;
}

- (NSDictionary *)dictionaryRepresentation
{
	NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:5];
	NSDictionary *returnDict;
	
	NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:XMURLType_Callto];
	[dictionary setObject:number forKey:XMKey_URLType];
	[number release];
	
	if(url)
	{
		[dictionary setObject:url forKey:XMKey_URLString];
	}
	
	number = [[NSNumber alloc] initWithUnsignedInt:type];
	[dictionary setObject:number forKey:XMKey_CalltoURLType];
	[number release];
	
	if(address)
	{
		[dictionary setObject:address forKey:XMKey_URLAddress];
	}
	if(port!= 0)
	{
		number = [[NSNumber alloc] initWithUnsignedInt:port];
		[dictionary setObject:number forKey:XMKey_URLPort];
		[number release];
	}
	
	if(conferenceToJoin)
	{
		[dictionary setObject:conferenceToJoin forKey:XMKey_CalltoURLConferenceToJoin];
	}
	
	if(gkHost)
	{
		[dictionary setObject:gkHost forKey:XMKey_CalltoURLGatekeeperHost];
	}
	
	returnDict = [[dictionary copy] autorelease];
	[dictionary release];
	return returnDict;
}

#pragma mark Getter and Setter Methods

- (XMCalltoURLType)type
{
	return type;
}

- (void)setType:(XMCalltoURLType)newType
{
	if(type != newType)
	{
		type = newType;
		
		// invalidating the cached url string
		[url release];
		url = nil;
	}
}

- (XMCallProtocol)callProtocol
{
	return XMCallProtocol_H323;
}

- (NSString *)address
{
	return address;
}

- (void)setAddress:(NSString *)newAddress
{
	if([self _setAddress:newAddress])
	{
		[url release];
		url = nil;
	}
}

- (BOOL)_setAddress:(NSString *)newAddress
{
	if(![newAddress isEqualToString:address])
	{
		NSString *old = address;
		address = [newAddress copy];
		[old release];
		
		return YES;
	}
	return NO;
}

- (unsigned)port
{
	return port;
}

- (void)setPort:(unsigned)newPort
{
	if([self _setPort:newPort])
	{
		[url release];
		url = nil;
	}
}

- (BOOL)_setPort:(unsigned)newPort
{
	if(port != newPort)
	{
		port = newPort;
		return YES;
	}
	return NO;
}

- (NSString *)conferenceToJoin
{
	return conferenceToJoin;
}

- (void)setConferenceToJoin:(NSString *)newConference
{
	if([self _setConferenceToJoin:newConference])
	{
		[url release];
		url = nil;
	}
}

- (BOOL)_setConferenceToJoin:(NSString *)newConference
{
	if(![newConference isEqualToString:conferenceToJoin])
	{
		NSString *old = conferenceToJoin;
		conferenceToJoin = [newConference copy];
		[old release];
		
		return YES;
	}
	
	return NO;
}

- (NSString *)gatekeeperHost
{
	return gkHost;
}

- (void)setGatekeeperHost:(NSString *)newHost
{
	if(![newHost isEqualToString:gkHost])
	{
		NSString *old = gkHost;
		gkHost = [newHost copy];
		[old release];
		
		// invalidating the cached url string
		[url release];
		url = nil;
	}
}

- (NSString *)humanReadableRepresentation
{
	return [self addressPart];
}

- (NSString *)addressPart;
{
	
	if(address == nil)
	{
		return nil;
	}
	
	if(conferenceToJoin && port != 0)
	{
		return [NSString stringWithFormat:@"%@:%d**%@", address, port, conferenceToJoin];
	}
	else if(conferenceToJoin)
	{
		return [NSString stringWithFormat:@"%@**%@", address, conferenceToJoin];
	}
	else if(port != 0)
	{
		return [NSString stringWithFormat:@"%@:%d", address, port];
	}
	else
	{
		return address;
	}
}

- (BOOL)setAddressPart:(NSString *)addressPart
{
	return [self _parseAddressPart:addressPart allowPortSpecification:YES];
}

- (BOOL)_parseAddressPart:(NSString *)addressPart allowPortSpecification:(BOOL)allowPortSpecification
{
	NSScanner *scanner = [[NSScanner alloc] initWithString:addressPart];
	NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@":*"];
	
	BOOL parsingCorrect = YES;
	
	NSString *newAddress;
	int newPort;
	NSString *newConferenceToJoin;
	
	if(![scanner scanUpToCharactersFromSet:charSet intoString:&newAddress])
	{
		parsingCorrect = NO;
	}
	
	if([scanner scanString:@":" intoString:nil])
	{
		if(!allowPortSpecification || ![scanner scanInt:&newPort])
		{
			parsingCorrect = NO;
		}
	}
	else
	{
		newPort = 0;
	}
	
	if([scanner scanString:@"**" intoString:nil])
	{
		if(![scanner scanUpToCharactersFromSet:charSet intoString:&newConferenceToJoin])
		{
			parsingCorrect = NO;
		}
	}
	else
	{
		newConferenceToJoin = nil;
	}
	
	if(![scanner isAtEnd])
	{
		parsingCorrect = NO;
	}
	
	[scanner release];
	
	if(!parsingCorrect)
	{
		return NO;
	}
	
	BOOL a = [self _setAddress:newAddress];
	BOOL b = [self _setPort:newPort];
	BOOL c = [self _setConferenceToJoin:newConferenceToJoin];
	
	if(a || b || c)
	{
		// something has changed
		[url release];
		url = nil;
	}
	
	return YES;
}

@end
