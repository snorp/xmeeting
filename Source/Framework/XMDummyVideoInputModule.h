/*
 * $Id: XMDummyVideoInputModule.h,v 1.6 2007/03/12 13:33:50 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_DUMMY_VIDEO_INPUT_MODULE_H__
#define __XM_DUMMY_VIDEO_INPUT_MODULE_H__

#import <Cocoa/Cocoa.h>
#import "XMVideoInputModule.h"

@interface XMDummyVideoInputModule : NSObject <XMVideoInputModule> {

	id<XMVideoInputManager> inputManager;
	
	NSArray *device;
	
	XMVideoSize videoSize;
}

- (id)_init;

+ (CVPixelBufferRef)getDummyImageForVideoSize:(XMVideoSize)videoSize; //XMVideoSize_NoVideo releases buffer

@end

#endif // __XM_DUMMY_VIDEO_INPUT_MODULE_H__
