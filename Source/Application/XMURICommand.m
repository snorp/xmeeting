/*
 * $Id: XMURICommand.m,v 1.3 2007/05/28 09:56:04 hfriederich Exp $
 *
 * Copyright (c) 2006-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2007 Hannes Friederich. All rights reserved.
 */

#import "XMeeting.h"
#import "XMURICommand.h"
#import "XMCallAddressManager.h"
#import "XMSimpleAddressResource.h"

@implementation XMURICommand

+ (NSString *)tryToCallAddress:(NSString *)addressString
{
    XMCallAddressManager * callManager = [XMCallAddressManager sharedInstance];
    
    if ([callManager activeCallAddress] == nil)
    {
        // De-escape the address string before using it further
        addressString = [addressString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        XMAddressResource *addressResource = [XMAddressResource addressResourceWithStringRepresentation:addressString];
        if (addressResource != nil) {
            
            id<XMCallAddress> callAddress = [callManager addressMatchingResource:addressResource];
            if (callAddress == nil) {
                callAddress = [[[XMSimpleAddressResourceWrapper alloc] initWithAddressResource:addressResource] autorelease];
            }
            [callManager makeCallToAddress:callAddress];
            return nil;
        }
        else
        {
            NSString *formatString = NSLocalizedString(@"XM_ILLEGAL_URI", @"");
            return [NSString stringWithFormat:formatString, addressString];
        }
    }
    else
    {
        return NSLocalizedString(@"XM_ALREADY_IN_CALL", @"");
    }
}

- (id)performDefaultImplementation
{
    NSString *command = [[self commandDescription] commandName];
    NSString *urlString = [self directParameter]; 
    NSString *errorString = nil;
	
    if ([command isEqualToString:@"GetURL"] ||
        [command isEqualToString:@"OpenURL"])
    {
        errorString = [XMURICommand tryToCallAddress:urlString];
    }
    else
    {
        errorString = @"<Unknown command>";
    }
    
    if (errorString != nil)
    {
        [[NSSound soundNamed:@"Funk"] play];
        [self setScriptErrorString:errorString];
    }
        
    return nil;
}

@end
