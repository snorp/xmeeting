/*
 * $Id: XMCallManager.h,v 1.1 2005/02/11 12:58:44 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class XMPreferences, XMCallInfo;


@interface XMCallManager : NSObject {
	
	id delegate;
	XMPreferences *activePreferences;
	
	XMCallInfo *activeCall;

}

+ (XMCallManager *)sharedInstance;

- (id)delegate;
- (void)setDelegate:(id)delegate;

- (BOOL)startH323Listening;
- (void)stopH323Listening;
- (BOOL)isH323Listening;

- (XMPreferences *)activePreferences;
- (void)setActivePreferences:(XMPreferences *)prefs;

- (XMCallInfo *)activeCall;

@end
