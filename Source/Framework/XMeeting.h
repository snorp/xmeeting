/*
 * $Id: XMeeting.h,v 1.1 2005/06/23 12:35:56 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XMEETING_H__
#define __XMEETING_H__

/**
 * Before using any classes and methods of the XMeeting framework,
 * call this function to ensure that everything is initalized properly
 **/
void InitXMeetingFramework();

#import "XMTypes.h"
#import "XMStringConstants.h"

#import "XMUtils.h"

#import "XMCallManager.h"
#import "XMCallInfo.h"
#import "XMPreferences.h"

#import "XMCodecManager.h"

#import "XMAudioManager.h"

#import "XMVideoManager.h"
#import "XMLocalVideoView.h"

#import "XMAddressBookManager.h"

#import "XMURL.h"
#import "XMCalltoURL.h"

#endif // __XMEETING_H__

