/*
 * $Id: XMOSDVideoView.h,v 1.9 2007/08/17 11:36:44 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Ivan Guajana. All rights reserved.
 */

#ifndef __XM_OSD_VIDEO_VIEW_H__
#define __XM_OSD_VIDEO_VIEW_H__

#import <Cocoa/Cocoa.h>
#import "XMeeting.h"

#import "XMOpenGLUtilities.h"

typedef enum XMPinPMode
{
  XMPinPMode_NoPinP = 0,
  XMPinPMode_Classic,
  XMPinPMode_3D,
  XMPinPMode_SideBySide
  
} XMPinPMode;

typedef enum XMOSDDisplayMode
{
  XMOSDDisplayMode_NoOSD = 0,
  XMOSDDisplayMode_AlwaysVisible,
  XMOSDDisplayMode_AutomaticallyHiding
  
} XMOSDDisplayMode;

typedef enum XMOpeningEffect 
{
  XMOpeningEffect_NoEffect,
  XMOpeningEffect_FadeIn,
  XMOpeningEffect_RollInFromBottomBorder
} XMOpeningEffect;

typedef enum XMClosingEffect
{
  XMClosingEffect_NoEffect,
  XMClosingEffect_FadeOut,
  XMClosingEffect_RollOutToBottomBorder,
  
} XMClosingEffect;

@class XMOnScreenControllerView, XMOnScreenControllerWindow;

/**
 * A view that draws either the remote
 * video or both local and remote within its frame
 * with OSD on mouse enter
 **/
@interface XMOSDVideoView : NSView <XMVideoView> {

@private
  unsigned displayStatus;
  
  NSOpenGLContext *openGLContext;
  NSSize displaySize;
  CVOpenGLTextureRef noVideoTexture;
  
  // only used to draw into the window draw buffer when
  // the window does miniaturize or there is no local video
  // (e.g. when the device is changed)
  BOOL isMiniaturized;
  
  // displayed when -startDisplayingNoVideo is called
  NSImage *noVideoImage;
  
  //on screen display
  XMOnScreenControllerView *osd;
  XMOnScreenControllerWindow *osdControllerWindow;
  XMOSDDisplayMode osdDisplayMode;
  BOOL doesShowOSD;
  NSTrackingRectTag osdTrackingRect;
  XMOpeningEffect osdOpeningEffect;
  XMClosingEffect osdClosingEffect;
  
  //Fullscreen stuff
  BOOL isFullScreen;
  
  //Picture-in-picture stuff
  NSRect pinpRect;	// rect of local video for classic PinP.
  NSPoint downPoint; //store the distance of the mouse click from the local view's center (in classic PinP)
  Scene noPinP, classicPinP, sideBySidePinP, roomPinP, temporaryScene;
  Scene *currentPinPMode;
  Scene *targetPinPMode, *initialPinPMode; //used for animation
  NSAnimation *sceneAnimation;
  BOOL switchedPinPMode;
  BOOL enableComplexPinPModes;
  
  // mirroring local video
  BOOL doMirror;
  BOOL isLocalVideoMirrored;
}

// determines whether video will be displayed and how
- (void)startDisplayingVideo;
- (void)stopDisplayingVideo;
- (BOOL)doesDisplayVideo;
- (BOOL)enableComplexPinPModes;
- (void)setEnableComplexPinPModes:(BOOL)flag;
- (XMPinPMode)pinpMode;
- (void)setPinPMode:(XMPinPMode)mode animate:(BOOL)animate;

// used in case video isn't enabled in preferences
- (void)startDisplayingNoVideo;
- (void)stopDisplayingNoVideo;
- (BOOL)doesDisplayNoVideo;
- (NSImage *)noVideoImage;
- (void)setNoVideoImage:(NSImage *)image;

// sets / gets how the OSD should behave
- (XMOSDDisplayMode)osdDisplayMode;
- (void)setOSDDisplayMode:(XMOSDDisplayMode)mode;
- (XMOpeningEffect)osdOpeningEffect;
- (void)setOSDOpeningEffect:(XMOpeningEffect)effect;
- (XMClosingEffect)osdClosingEffect;
- (void)setOSDClosingEffect:(XMClosingEffect)effect;
- (void)releaseOSD;	// causes the osd to be released

// sets whether we have full screen or not
// affects the OSD
- (BOOL)isFullScreen;
- (void)setFullScreen:(BOOL)flag;

// sets whether the local video is drawn mirrored or not
- (BOOL)isLocalVideoMirrored;
- (void)setLocalVideoMirrored:(BOOL)flag;

// Sets / Gets display settings
- (NSString *)settings;
- (void)setSettings:(NSString *)settings;

@end

#endif // __XM_OSD_VIDEO_VIEW_H__
