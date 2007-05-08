/*
 * $Id: XMURICommand.m,v 1.2 2007/05/08 15:18:40 hfriederich Exp $
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

- (id)performDefaultImplementation
{
    XMCallAddressManager * callManager = [XMCallAddressManager sharedInstance];
    
    if ([callManager activeCallAddress] == nil)
    {
        NSString *command = [[self commandDescription] commandName];
        NSString *urlString = [self directParameter]; 
	
        if ([command isEqualToString:@"GetURL"] ||
            [command isEqualToString:@"OpenURL"])
        {
            XMAddressResource *addressResource = [XMAddressResource addressResourceWithStringRepresentation:urlString];
            if (addressResource != nil) {
                XMSimpleAddressResourceWrapper * wrapper = [[XMSimpleAddressResourceWrapper alloc] initWithAddressResource:addressResource];
                [callManager makeCallToAddress:wrapper];
                [wrapper release];
            }
        }
    }
        
    return nil;
}

@end
