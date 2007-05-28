/*
 * $Id: XMURICommand.h,v 1.2 2007/05/28 09:56:04 hfriederich Exp $
 *
 * Copyright (c) 2006-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_URI_COMMAND_H__
#define __XM_URI_COMMAND_H__

#import <Cocoa/Cocoa.h>

@interface XMURICommand : NSScriptCommand {

}

+ (NSString *)tryToCallAddress:(NSString *)addressString;

@end

#endif // __XM_URI_COMMAND_H__
