/*
 * $Id: XMDummyVideoInputModule.h,v 1.3 2006/02/21 22:38:59 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
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
