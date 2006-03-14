/*
 * $Id: XMDummyVideoInputModule.h,v 1.4 2006/03/14 23:05:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_DUMMY_VIDEO_INPUT_MODULE_H__
#define __XM_DUMMY_VIDEO_INPUT_MODULE_H__

#import <Cocoa/Cocoa.h>
#import "XMVideoInputModule.h"

@interface XMDummyVideoInputModule : NSObject <XMVideoInputModule> {

	id<XMVideoInputManager> inputManager;
	
	NSArray *device;
	
	NSSize size;
	CVPixelBufferRef pixelBuffer;
}

- (id)_init;

@end

#endif // __XM_DUMMY_VIDEO_INPUT_MODULE_H__
