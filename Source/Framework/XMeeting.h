/*
 * $Id: XMeeting.h,v 1.8 2006/02/07 18:06:05 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XMEETING_H__
#define __XMEETING_H__

/**
 * Before using any classes and methods of the XMeeting Framework,
 * call this function to ensure that everything is initalized properly.
 * Due to the multithreaded nature of this framework, the framework should
 * not be used before the NSAppliationDidFinishLaunchingNotification has
 * been posted. Otherwise, one might experience that the application
 * no longer responds to user events or does draw on screen at all.
 **/
void XMInitFramework();

/**
 * Call this method when you want to shutdown the XMeeting framework.
 * If you want to terminate the appliation process, you should wait
 * until the appropriate notification will be called
 * (XMNotification_FrameworkDidClose)
 * After calling this function, it is no longer safe to use the
 * classes and methods of the XMeeting Framework.
 * Afther this notification has been posted, it is safe to terminate
 * the application
 **/
void XMCloseFramework();

#import "XMTypes.h"
#import "XMStringConstants.h"

#import "XMUtils.h"

#import "XMCallManager.h"
#import "XMCallInfo.h"
#import "XMPreferences.h"
#import "XMPreferencesCodecListRecord.h"

#import "XMCodecManager.h"
#import "XMCodec.h"

#import "XMAudioManager.h"

#import "XMVideoManager.h"
#import "XMVideoView.h"
#import "XMVideoModule.h"

#import "XMAddressResource.h"
#import "XMGeneralPurposeAddressResource.h"

#endif // __XMEETING_H__

