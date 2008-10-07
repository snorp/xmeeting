/*
 * $Id: XMStillImageVideoInputModule.h,v 1.4 2008/10/07 23:19:17 hfriederich Exp $
 *
 * Copyright (c) 2006-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2007 Mark Fleming, Hannes Friederich. All rights reserved.
 */

/*!
	@header XMStillImageVideoInputModule.h
	@discussion	XMVideoInputManager still image implementation, 
	
	Creates a CVPixelBuffer of the image data.
	
	grabFrame routine does the update via: 
		[inputManager handleGrabbedFrame:pixelBuffer time:timeStamp];
			
*/

#ifndef __XM_STILL_IMAGE_VIDEO_INPUT_MODULE_H__
#define __XM_STILL_IMAGE_VIDEO_INPUT_MODULE_H__

#import <Cocoa/Cocoa.h>
#import "XMVideoInputModule.h"

@interface XMStillImageVideoInputModule : NSObject <XMVideoInputModule> {

@private
  id<XMVideoInputManager> inputManager;
  NSArray *stillNames;
  
  BOOL preserveImagePath;
  NSString *imagePath;	
  XMImageScaleOperation scaleType;		
    //XMImageScaleOperation_NoScaling = 0,
    //XMImageScaleOperation_ScaleProportionally,
    //XMImageScaleOperation_ScaleToFit
  
  XMVideoSize videoSize;			// required size of output image.
  
  NSString *actualImagePath;		// path used to read the image from
  XMImageScaleOperation actualScaleType;		// scaleType to be used
  CVPixelBufferRef pixelBuffer;	// buffer returned on call to -grabFrame
                                // Note: typedef CVBufferRef = CVImageBufferRef = CVPixelBufferRef;
  
  // Setting Dialog settings: Path and preview image..
  IBOutlet NSView *deviceSettingsView;
  IBOutlet NSImageView *previewImage;
  IBOutlet NSPopUpButton *imageScaling;
  IBOutlet NSTextField *pathField;
  
  IBOutlet NSView *moduleSettingsView;
  IBOutlet NSButton *preserveImagePathSwitch;
}

- (id)_init;
- (IBAction)_changeImage:(id)sender;
- (IBAction)_scaleTypeChanged:(id)sender;

- (IBAction)_togglePreserveImagePath:(id)sender;

@end

#endif // __XM_STILL_IMAGE_VIDEO_INPUT_MODULE_H__
