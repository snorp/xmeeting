/*
 * $Id: XMLocalVideoView.m,v 1.5 2008/11/03 21:34:03 hfriederich Exp $
 *
 * Copyright (c) 2006-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2008 Hannes Friederich, Ivan Guajana. All rights reserved.
 */

#import "XMLocalVideoView.h"

#import <OpenGL/OpenGL.h>
#import <QuartzCore/QuartzCore.h>

#import "XMWindow.h"

#define XM_DISPLAY_NOTHING 0
#define XM_DISPLAY_LOCAL_VIDEO 1
#define XM_DISPLAY_NO_VIDEO 2

@interface XMLocalVideoView (PrivateMethods)

- (void)_init;
- (void)_windowWillMiniaturize:(NSNotification *)notif;
- (void)_windowDidDeminiaturize:(NSNotification *)notif;
- (void)_didStartSelectedInputDeviceChange:(NSNotification *)notif;
- (void)_didChangeSelectedInputDevice:(NSNotification *)notif;
- (void)_checkNeedsMirroring;

@end

@implementation XMLocalVideoView

#pragma mark Init & Deallocation Methods

- (id)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame:frameRect];
  
  [self _init];
  
  return self;
}

- (void)_init
{
  XMVideoManager *videoManager = [XMVideoManager sharedInstance];
  
  displayStatus = XM_DISPLAY_NOTHING;

  // initializing the OpenGL structures
  NSOpenGLPixelFormat *openGLPixelFormat = [videoManager openGLPixelFormat];
  openGLContext = [[NSOpenGLContext alloc] initWithFormat:openGLPixelFormat shareContext:[videoManager openGLContext]];
  displaySize = NSMakeSize(0, 0);
  
  long swapInterval = 1;
  [openGLContext setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];
  
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  [notificationCenter addObserver:self selector:@selector(_windowWillMiniaturize:)
                             name:XMNotification_WindowWillMiniaturize object:nil];
  [notificationCenter addObserver:self selector:@selector(_windowDidDeminiaturize:)
                             name:NSWindowDidDeminiaturizeNotification object:nil];
  [notificationCenter addObserver:self selector:@selector(_didStartSelectedInputDeviceChange:)
                             name:XMNotification_VideoManagerDidStartSelectedInputDeviceChange object:nil];
  [notificationCenter addObserver:self selector:@selector(_didChangeSelectedInputDevice:)
                             name:XMNotification_VideoManagerDidChangeSelectedInputDevice object:nil];
  
  videoImageRep = nil;
  isMiniaturized = NO;
  
  busyWindow = nil;
  busyIndicator = nil;
  
  noVideoImage = nil;
  
  doMirror = NO;
  isLocalVideoMirrored = NO;
    
  drawsBorder = NO;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [openGLContext release];
  
  [busyWindow release];
  [busyIndicator release];
  
  [noVideoImage release];
  
  [super dealloc];
}

#pragma mark -
#pragma mark Overriding NSView methods

- (void)drawRect:(NSRect)rect
{
  if (displayStatus == XM_DISPLAY_LOCAL_VIDEO) {
    // if we have to redraw, we force an instant update of the window to prevent flickering
    XMVideoManager *videoManager = [XMVideoManager sharedInstance];
    [videoManager forceRenderingForView:self];
  } else if (displayStatus == XM_DISPLAY_NO_VIDEO && noVideoImage != nil) {
    NSSize size = [noVideoImage size];
    [noVideoImage drawInRect:[self bounds] fromRect:NSMakeRect(0, 0, size.width, size.height) operation:NSCompositeCopy fraction:1.0];
  } else {
    NSDrawWindowBackground(rect);
        
    if (drawsBorder == YES) {
      NSFrameRect([self bounds]);
    }
  }
}

- (BOOL)isOpaque
{
  return YES;
}

#pragma mark -
#pragma mark public Methods

- (void)startDisplayingLocalVideo
{
  if (displayStatus == XM_DISPLAY_LOCAL_VIDEO) {
    return;
  }
  
  [self stopDisplayingNoVideo];
  
  XMVideoManager *videoManager = [XMVideoManager sharedInstance];
  
  [openGLContext clearDrawable];
  
  [openGLContext setView:self];
  
  [self _checkNeedsMirroring];
  
  displayStatus = XM_DISPLAY_LOCAL_VIDEO;
  [videoManager addVideoView:self];
}

- (void)stopDisplayingLocalVideo
{  
  if (displayStatus != XM_DISPLAY_LOCAL_VIDEO) {
    return;
  }
  
  XMVideoManager *videoManager = [XMVideoManager sharedInstance];
  
  [videoManager removeVideoView:self];
  
  // removing the busy window if visible
  [self _didChangeSelectedInputDevice:nil];
  
  displayStatus = XM_DISPLAY_NOTHING;
  
  [self display];
  
  [openGLContext clearDrawable];
}

- (BOOL)doesDisplayLocalVideo
{
  return (displayStatus == XM_DISPLAY_LOCAL_VIDEO);
}

- (BOOL)isLocalVideoMirrored
{
  return isLocalVideoMirrored;
}

- (void)setLocalVideoMirrored:(BOOL)flag
{
  isLocalVideoMirrored = flag;
  
  [self _checkNeedsMirroring];
}

- (BOOL)drawsBorder
{
  return drawsBorder;
}

- (void)setDrawsBorder:(BOOL)flag
{
  drawsBorder = flag;
}

- (void)startDisplayingNoVideo
{
  if (displayStatus == XM_DISPLAY_NO_VIDEO) {
    return;
  }
  
  [self stopDisplayingLocalVideo];
  
  displayStatus = XM_DISPLAY_NO_VIDEO;
  
  [self setNeedsDisplay:YES];
}

- (void)stopDisplayingNoVideo
{
  if (displayStatus != XM_DISPLAY_NO_VIDEO) {
    return;
  }
  
  displayStatus = XM_DISPLAY_NOTHING;
  
  [self setNeedsDisplay:YES];
}

- (BOOL)doesDisplayNoVideo
{
  return (displayStatus == XM_DISPLAY_NO_VIDEO);
}

- (NSImage *)noVideoImage
{
  return noVideoImage;
}

- (void)setNoVideoImage:(NSImage *)image
{
  NSImage *old = noVideoImage;
  noVideoImage = [image retain];
  [old release];
}

#pragma mark -
#pragma mark XMVideoView protocol Methods

- (void)renderLocalVideo:(CVOpenGLTextureRef)localVideo didChange:(BOOL)localVideoDidChange 
       remoteVideo:(CVOpenGLTextureRef)remoteVideo didChange:(BOOL)remoteVideoDidChange
        isForced:(BOOL)isForced
{  
  if ([openGLContext view] == nil) {
    return;
  }
  
  if (isForced == NO && localVideoDidChange == NO) {
    return;
  }
  
  if (isForced == YES) {
    if (isMiniaturized == YES) {
      if (videoImageRep == nil && localVideo != NULL) {
        CIImage *image = [[CIImage alloc] initWithCVImageBuffer:localVideo];
        videoImageRep = [[NSCIImageRep alloc] initWithCIImage:image];
        [image release];
      }
      
      if (videoImageRep != nil) {
        [videoImageRep drawInRect:[self bounds]];
      }
      
      return;
    } else if (videoImageRep != nil) {
      [videoImageRep release];
      videoImageRep = nil;
    }
    
    if (localVideo == nil) {
      NSDrawWindowBackground([self bounds]);
      return;
    }
  }
  
  // activating this context
  [openGLContext makeCurrentContext];
  
  // adjusting for any size changes
  NSSize newSize = [self bounds].size;
  if (!NSEqualSizes(newSize, displaySize)) {
    [openGLContext update];
    glViewport(0, 0, (GLint)newSize.width, (GLint)newSize.height);
    
    displaySize = newSize;
  }
  
  // drawing the local video
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  
  // getting info about the texture to draw
  GLenum target = CVOpenGLTextureGetTarget(localVideo);
  GLint name = CVOpenGLTextureGetName(localVideo);
  GLfloat topLeft[2], topRight[2], bottomRight[2], bottomLeft[2];
  CVOpenGLTextureGetCleanTexCoords(localVideo, bottomLeft, bottomRight, topRight, topLeft);
  
  // drawing the texture
  glEnable(target);
  glBindTexture(target, name);
  
  glBegin(GL_QUADS);
  if (doMirror == NO) {
    glTexCoord2fv(bottomLeft); glVertex2f(-1, -1);
    glTexCoord2fv(topLeft); glVertex2f(-1, 1);
    glTexCoord2fv(topRight); glVertex2f(1, 1);
    glTexCoord2fv(bottomRight); glVertex2f(1, -1);
  } else {
    glTexCoord2fv(bottomLeft); glVertex2f(1, -1);
    glTexCoord2fv(topLeft); glVertex2f(1, 1);
    glTexCoord2fv(topRight); glVertex2f(-1, 1);
    glTexCoord2fv(bottomRight); glVertex2f(-1, -1);
  }
  glEnd();
  
  glDisable(target);
  
  // Flush the buffer to let the changes propagate to the screen
  glFlush();
}

#pragma mark -
#pragma mark Private Methods

- (void)_windowWillMiniaturize:(NSNotification *)notif
{
  if ([notif object] == [self window]) {
    isMiniaturized = YES;
    
    [self display];
  }
}

- (void)_windowDidDeminiaturize:(NSNotification *)notif
{
  if ([notif object] == [self window]) {
    isMiniaturized = NO;
  }
}

- (void)_didStartSelectedInputDeviceChange:(NSNotification *)notif
{
  if ([self window] == nil || displayStatus != XM_DISPLAY_LOCAL_VIDEO) {
    return;
  }

  if (busyWindow == nil) {
    busyIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 32, 32)];
    [busyIndicator setIndeterminate:YES];
    [busyIndicator setStyle:NSProgressIndicatorSpinningStyle];
    [busyIndicator setControlSize:NSRegularControlSize];
    [busyIndicator setDisplayedWhenStopped:YES];
    [busyIndicator setAnimationDelay:(5.0/60.0)];
    [busyIndicator setAutoresizingMask:(NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin)];
    [busyIndicator sizeToFit];
    
    busyWindow = [[XMChildWindow alloc] initWithContentRect:NSMakeRect(0, 0, 32, 32) styleMask:NSBorderlessWindowMask 
                                                    backing:NSBackingStoreBuffered defer:YES];
    
    [busyIndicator setControlTint:NSBlueControlTint];
    [busyWindow setContentView:busyIndicator];
    [busyWindow setAlphaValue:1.0];
    [busyWindow setBackgroundColor:[NSColor clearColor]];
    [busyWindow setOpaque:NO];
  }
  
  NSRect frame = [self bounds];
  NSPoint startPoint = NSMakePoint(((frame.size.width - 32.0) / 2.0), ((frame.size.height - 32.0) / 2.0));
  NSPoint windowPoint = [self convertPoint:startPoint toView:nil];
  NSPoint screenPoint = [[self window] convertBaseToScreen:windowPoint];
  
  frame = [busyWindow frame];
  frame.origin.x = screenPoint.x;
  frame.origin.y = screenPoint.y;
  [busyWindow setFrame:frame display:NO];
  
  [busyIndicator startAnimation:self];
  [[self window] addChildWindow:busyWindow ordered:NSWindowAbove];
}

- (void)_didChangeSelectedInputDevice:(NSNotification *)notif
{
  if ([busyWindow isVisible]) {
    [busyIndicator stopAnimation:self];
    [[self window] removeChildWindow:busyWindow];
    [busyWindow orderOut:self];
  }
  
  [self _checkNeedsMirroring];
}

- (void)_checkNeedsMirroring
{
  if (isLocalVideoMirrored == NO) {
    doMirror = NO;
  } else {
    XMVideoManager *videoManager = [XMVideoManager sharedInstance];
    id<XMVideoModule> videoModule = [videoManager videoModuleProvidingSelectedInputDevice];
    if ([[videoModule identifier] isEqualToString:@"XMSequenceGrabberVideoInputModule"]) {
      doMirror = YES;
    } else {
      doMirror = NO;
    }
  }
}

@end
