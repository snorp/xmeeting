/*
 * $Id: XMURICommand.h,v 1.4 2007/08/17 11:36:41 hfriederich Exp $
 *
 * Copyright (c) 2006-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_URI_COMMAND_H__
#define __XM_URI_COMMAND_H__

#import <Cocoa/Cocoa.h>
#import "XMeeting.h"

@interface XMURICommand : NSScriptCommand {
}

+ (NSString *)tryToCallAddress:(NSString *)addressString;

@end

@interface XMeetingURL : XMAddressResource {
  
@private
  NSString *url;
  NSString *username;
  NSString *host;
  XMCallProtocol callProtocol;
}

+ (BOOL)isXMeetingURL:(NSString *)url;

- (id)initWithString:(NSString *)url;

@end

#endif // __XM_URI_COMMAND_H__
