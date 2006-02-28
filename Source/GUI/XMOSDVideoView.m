/*
 * $Id: XMOSDVideoView.m,v 1.2 2006/02/28 09:14:48 zmit Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Ivan Guajana. All rights reserved.
 */

#import "XMOSDVideoView.h"

#import <OpenGL/OpenGL.h>
#import <GLUT/glut.h>
#import <QuartzCore/QuartzCore.h>

#import "XMWindow.h"
#import "XMMainWindowController.h"
#import "XMApplicationController.h"
#import "XMPreferencesManager.h"
#import "XMInspectorController.h"

#import "XMInCallOSD.h"
#import "XMAudioOnlyOSD.h"

#import "XMVideoManager.h"

#import "XMOpenGLUtilities.h"


#define XM_DISPLAY_NO_VIDEO 0
#define XM_DISPLAY_LOCAL_VIDEO 1
#define XM_DISPLAY_REMOTE_VIDEO 2
#define XM_DISPLAY_LOCAL_AND_REMOTE_VIDEO 3

#define XM_ANIMATION_STEPS 60.0

#define __ANTIALIASED_POLY__ 1


@interface XMOSDVideoView (PrivateMethods)

- (void)_init;
- (void)_windowWillMiniaturize:(NSNotification *)notif;
- (void)_windowDidDeminiaturize:(NSNotification *)notif;
- (void)_didStartSelectedInputDeviceChange:(NSNotification *)notif;
- (void)_didChangeSelectedInputDevice:(NSNotification *)notif;
- (void)_frameDidChange:(NSNotification *)notif;
- (void)_resetTrackingRect;
- (void)_displayTimeout:(NSTimer*)t;
- (void)_windowWillClose:(NSNotification *)notif;
- (void)_displayOSDWithSize:(int)size;
- (void)_preferencesDidChange:(NSNotification*)notif;

- (void)_startTimer;
- (void)_stopTimer;

//OSD Actions
- (void)goFullScreen;
- (void)goWindowedMode;
- (void)togglePictureInPicture;
- (void)nextPinPModeAnimating:(BOOL)animating;
- (void)hangup;
- (void)showInspector;
- (void)mute;
- (void)unmute;
- (void)showTools;

//Drawing
- (void)_drawPolygon:(GLfloat)depth bottomLeft:(GLfloat*)bottomLeft bottomRight:(GLfloat*)bottomRight topRight:(GLfloat*)topRight topLeft:(GLfloat*)topLeft;

//Animating
- (void)animation:(NSAnimation *)animation didReachProgressMark:(NSAnimationProgress)progress;
- (void)animationDidEnd:(NSAnimation *)animation;
- (void)animationDidStop:(NSAnimation *)animation;

//Notifications
- (void)_callCleared:(NSNotification*)notif;

- (void)_setTrackingRect;
- (void)_removeTrackingRect;
@end

@implementation XMEventAwareWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag screen:(NSScreen *)aScreen{
	self = [super initWithContentRect:contentRect 
									 styleMask:styleMask 
									   backing:bufferingType 
										 defer:flag
										screen:aScreen];
	
	if (self){
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationSwitched:) name:NSApplicationDidResignActiveNotification object:nil];
	}
	
	return self;
}

- (BOOL)canBecomeKeyWindow{
	return YES;
}

- (void)applicationSwitched:(NSNotification *)aNotification{
	//if the camera is activated when in fullscreen, it may happen that ichat
	//will become the active application. To avoid this, we re-activate ourselves.
	[NSApp activateIgnoringOtherApps:YES];
	[self makeKeyAndOrderFront:nil];
	[self setLevel:NSScreenSaverWindowLevel];

}

- (void)resignKeyWindow{
}

- (void)resignMainWindow{
}

- (void)dealloc{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

@end

@implementation XMOSDVideoView

#pragma mark Init & Deallocation Methods

- (id)init
{
	self = [super init];
	
	[self _init];	
	return self;
}

- (id)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	
	[self _init];
	
	return self;
}

- (void)_init
{
	trackingRect = -1;
	fullscreen = NO;
	pinp = NO;
	switchedPinPMode = NO;
	
	shouldDisplayOSD = YES;
	
	noPinPScene.localVideoPlacement = XMMakePlacement(XMMakeVector3(0.0,0.0,-1.7), NO_SCALING, ROTATION_AXIS_Y, (GLfloat)0.0);
	noPinPScene.remoteVideoPlacement = XMMakePlacement(XMMakeVector3(0.0,0.0,-1.8), NO_SCALING, ROTATION_AXIS_Y, (GLfloat)0.0);	
	noPinPScene.camera = XMMakeCamera(XMMakeVector3(0.0, 0.0, 3.8), XMMakeVector3(0.0, 0.0, 0.0), ROTATION_AXIS_Y);
	
	//setting up PinP modes
	classicPinP.localVideoPlacement = XMMakePlacement(XMMakeVector3(0.65, -0.5, -1.7), XMMakeVector3(0.25, 0.25, 1.0), ROTATION_AXIS_Y, (GLfloat)0.0);
	classicPinP.remoteVideoPlacement = XMMakePlacement(XMMakeVector3(0.0,0.0,-1.8), NO_SCALING, ROTATION_AXIS_Y, (GLfloat)0.0);	
	classicPinP.camera = XMMakeCamera(XMMakeVector3(0.0,0.0,2.0), XMMakeVector3(0.0, 0.0, -1.0), ROTATION_AXIS_Y);
	
	sideBySidePinP.localVideoPlacement = XMMakePlacement(XMMakeVector3(0.65, 0.0, -2.0), XMMakeVector3(0.48, 0.48, 1.0), ROTATION_AXIS_Y, (GLfloat)0.0);
	sideBySidePinP.remoteVideoPlacement = XMMakePlacement(XMMakeVector3(-0.65, 0.0,-2.0), XMMakeVector3(0.48, 0.48, 1.0), ROTATION_AXIS_Y, (GLfloat)0.0);	
	sideBySidePinP.camera = XMMakeCamera(XMMakeVector3(0.0,0.0,2.0), XMMakeVector3(0.0, 0.0, -1.0), ROTATION_AXIS_Y);
	
	ichatPinP.localVideoPlacement = XMMakePlacement(XMMakeVector3(0.6, 0.34, -3.0), XMMakeVector3(0.45, 0.45, 1.0), ROTATION_AXIS_Y, (GLfloat)25.0);
	ichatPinP.localVideoPlacement.isReflected = YES;
	ichatPinP.remoteVideoPlacement = XMMakePlacement(XMMakeVector3(-0.6, 0.34, -3.0), XMMakeVector3(0.45, 0.45, 1.0), ROTATION_AXIS_Y, (GLfloat)-25.0);
	ichatPinP.remoteVideoPlacement.isReflected = YES;
	ichatPinP.camera = XMMakeCamera(XMMakeVector3(0.0, 1.0, 1.1), XMMakeVector3(0.0, 0.0, -3.0), ROTATION_AXIS_Y);

	//currentPinPMode = &classicPinP;
	//currentPinPMode = &ichatPinP;
	currentPinPMode = &sideBySidePinP;
	initialPinPMode = currentPinPMode;
		
	openGLContext = nil;
	displayState = XM_DISPLAY_NO_VIDEO;
	previousSize = NSMakeSize(0, 0);
	
	ciRemoteImageRep = nil;
	noVideoImage = nil;
	
	isMiniaturized = NO;
	isBusy = NO;
	
	busyIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 32, 32)];
	[busyIndicator setIndeterminate:YES];
	[busyIndicator setStyle:NSProgressIndicatorSpinningStyle];
	[busyIndicator setControlSize:NSRegularControlSize];
	[busyIndicator setDisplayedWhenStopped:YES];
	[busyIndicator setAnimationDelay:(5.0/60.0)];
	[busyIndicator setAutoresizingMask:(NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin)];
	[busyIndicator sizeToFit];
	[busyIndicator setHidden:YES];
	
	[self addSubview:busyIndicator positioned:NSWindowAbove relativeTo:nil];
	
	NSRect ownBounds = [self bounds];
	NSRect busyIndicatorFrame = [busyIndicator frame];
	
	float x = (ownBounds.size.width - busyIndicatorFrame.size.width) / 2;
	float y = (ownBounds.size.height - busyIndicatorFrame.size.height) / 2;
	
	[busyIndicator setFrame:NSMakeRect(x, y, busyIndicatorFrame.size.width, busyIndicatorFrame.size.height)];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_callCleared:)
							   name:XMNotification_CallManagerDidClearCall
							 object:nil];

}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[self _stopTimer];
	
	if (trackingRect) {
		[self removeTrackingRect:trackingRect];
		trackingRect = 0;
	}
	
	[openGLContext release];
	
	if (noVideoImage) [noVideoImage release];
	noVideoImage = nil;
	
	[super dealloc];
}


- (void)applicationWillTerminate:(NSNotification *)notification
{
	if (!fullscreen) return;
	
	[fullscreenWindow orderOut:self];
	
	// Release the display(s)
	if (CGDisplayRelease( kCGDirectMainDisplay ) != kCGErrorSuccess) {
		NSLog( @"Couldn't release the display(s)! [XMOSDVideoView->applicationWillTerminate]" );
		// Note: if you display an error dialog here, make sure you set
		// its window level to the same one as the shield window level,
		// or the user won't see anything.
	}
}

#pragma mark -
#pragma mark Overriden NSView methods

- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{       
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:nil];
	[self _removeTrackingRect];
}

- (void)viewDidMoveToSuperview{
	if([self superview]){
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(_resetTrackingRect)
													 name:NSViewFrameDidChangeNotification
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_preferencesDidChange:)
													 name:XMNotification_PreferencesDidChange 
												   object:nil];
		
		[self performSelector:@selector(_setTrackingRect) withObject:nil afterDelay:0.0001];
	}
	else{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:XMNotification_PreferencesDidChange object:nil];
	}
}


- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)removeFromSuperview
{
    [self _removeTrackingRect];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[XMVideoManager sharedInstance] removeVideoView:self];
	[openGLContext release];
	openGLContext = nil;
	
    [super removeFromSuperview];
}

- (void)removeFromSuperviewWithoutNeedingDisplay
{
    [self _removeTrackingRect];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[XMVideoManager sharedInstance] removeVideoView:self];
	[openGLContext release];
	openGLContext = nil;
	
    [super removeFromSuperviewWithoutNeedingDisplay];
}

- (void)drawRect:(NSRect)rect
{
	XMVideoManager *videoManager = [XMVideoManager sharedInstance];
	
	if(openGLContext == nil)
	{
		// need to initialize the OpenGL structures first
		NSOpenGLPixelFormat *openGLPixelFormat = [videoManager openGLPixelFormat];
		openGLContext = [[NSOpenGLContext alloc] initWithFormat:openGLPixelFormat shareContext:[videoManager openGLContext]];
		
		long swapInterval = 1;
		[openGLContext setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];
		
		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		[notificationCenter addObserver:self selector:@selector(_windowWillMiniaturize:)
								   name:NSWindowWillMiniaturizeNotification object:[self window]];
		[notificationCenter addObserver:self selector:@selector(_windowDidDeminiaturize:)
								   name:NSWindowDidDeminiaturizeNotification object:[self window]];
		[notificationCenter addObserver:self selector:@selector(_didStartSelectedInputDeviceChange:)
								   name:XMNotification_VideoManagerDidStartSelectedInputDeviceChange object:nil];
		[notificationCenter addObserver:self selector:@selector(_didChangeSelectedInputDevice:)
								   name:XMNotification_VideoManagerDidChangeSelectedInputDevice object:nil];								   
		[notificationCenter addObserver:self selector:@selector(_windowWillClose:)
								   name:NSWindowWillCloseNotification object:nil];	
								   		

//		if(displayState == XM_DISPLAY_LOCAL_VIDEO)
//		{
//			isBusy = YES;
//			[busyIndicator startAnimation:self];
//			[busyIndicator setHidden:NO];
//		}
				
		// finally, register with the manager so that we get called every time a frame changed
		[videoManager addVideoView:self];
	}
	else
	{
		// if we simply have to redraw, we force an instant update of the window to prevent
		// flickering
		[videoManager forceRenderingForView:self];
	}
}


- (BOOL)isOpaque
{
	return YES;
}

#pragma mark -
#pragma mark public Methods

- (void)moduleWasDeactivated:(id)module{
	[self mouseExited:[NSApp currentEvent]];

	if (fullscreen){
		[self goWindowedMode];
		if ([osd respondsToSelector:@selector(setFullscreenState:)]){
			[(XMInCallOSD*)osd setFullscreenState:NO];
		}
	}
	else if ([[self window] isMiniaturized]){
		[[self window] deminiaturize:self];
	}
}


-(void)setShouldDisplayOSD:(BOOL)b{
	shouldDisplayOSD = b;
	
	if (shouldDisplayOSD){
		[self _startTimer];
	}
	else
	{
		[self _stopTimer];
		[self mouseExited:[NSApp currentEvent]];
	}
}

- (void)startDisplayingPinPVideo
{
	displayState = XM_DISPLAY_LOCAL_AND_REMOTE_VIDEO;
	switchedPinPMode= YES;
	
}

- (void)startDisplayingLocalVideo
{
	displayState = XM_DISPLAY_LOCAL_VIDEO;
	switchedPinPMode= YES;
}

- (void)startDisplayingRemoteVideo
{
	displayState = XM_DISPLAY_REMOTE_VIDEO;
	switchedPinPMode= YES;
}

- (void)stopDisplayingVideo
{
	displayState = XM_DISPLAY_NO_VIDEO;
	switchedPinPMode= YES;
}

- (void)renderNoVideo{
	if (noVideoImage == nil){
		noVideoImage = [[NSImage imageNamed:@"no_video_screen.tif"] retain];
	}
	[noVideoImage drawInRect:[self frame] fromRect:NSMakeRect(0,0,320,240) operation:NSCompositeCopy fraction:1.0];

}

- (void)renderLocalVideo:(CVOpenGLTextureRef)localVideo didChange:(BOOL)localVideoDidChange 
			 remoteVideo:(CVOpenGLTextureRef)remoteVideo didChange:(BOOL)remoteVideoDidChange
				isForced:(BOOL)isForced
{	
//	NSLog(@"renderLocalVideo isforced:%@ localChange:%@ remoteChange:%@", (isForced? @"YES":@"NO"), (localVideoDidChange? @"YES":@"NO"), (remoteVideoDidChange? @"YES":@"NO"));
	CVOpenGLTextureRef openGLTextureLocal = nil;
	CVOpenGLTextureRef openGLTextureRemote = nil;

	float videoHeight = [self bounds].size.height;
	float videoWidth = [self bounds].size.width;
	
	if (videoHeight/videoWidth != 4.0/3.0){	//ensure correct aspect ratio on wide screens
		videoWidth = 4.0/3.0 * videoHeight;
	}
	
	if(displayState == XM_DISPLAY_NO_VIDEO)
	{
		[self renderNoVideo];
		return;
	}
	
	if(isBusy == YES)
	{
		if([openGLContext view] != nil)
		{
			[openGLContext clearDrawable];
		}
		NSEraseRect([self bounds]);
		return;
	}

	if(displayState == XM_DISPLAY_LOCAL_VIDEO)
	{
		openGLTextureLocal = localVideo;
	}
	else if (displayState == XM_DISPLAY_REMOTE_VIDEO)
	{
		openGLTextureRemote = remoteVideo;
	}
	else //both
	{
		openGLTextureLocal = localVideo;
		openGLTextureRemote = remoteVideo;
	}
	
	if([openGLContext view] == nil)
	{
		[openGLContext setView:self];
	}
	
	// activating this context
	[openGLContext makeCurrentContext];
	
	// adjusting for any size changes
	NSSize newSize = [self bounds].size;
	
	if (isMiniaturized && openGLTextureRemote != nil){
		CIImage *image = [[CIImage alloc] initWithCVImageBuffer:openGLTextureRemote];
		ciRemoteImageRep = [[NSCIImageRep alloc] initWithCIImage:image];
		[image release];
		[ciRemoteImageRep drawInRect:[self bounds]];
		return;
	}
	
	if (!NSEqualSizes(newSize, previousSize) || switchedPinPMode)
	{
		[openGLContext update];

		glViewport(0, 0, (GLint)newSize.width, (GLint)newSize.height);
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		gluPerspective(30.0,(GLdouble)newSize.width/(GLdouble)newSize.height,0.1,100.0);
		
		Camera currentCamera;
		if (displayState == XM_DISPLAY_LOCAL_AND_REMOTE_VIDEO){
			currentCamera = currentPinPMode->camera;
		}
		else
		{
			currentCamera = noPinPScene.camera;
		}	
		gluLookAt(currentCamera.eye.x, currentCamera.eye.y, currentCamera.eye.z, currentCamera.sceneCenter.x, currentCamera.sceneCenter.y,
					currentCamera.sceneCenter.z, currentCamera.upVector.x, currentCamera.upVector.y, currentCamera.upVector.z);
		
		glMatrixMode(GL_MODELVIEW);

		previousSize = newSize;
		
		switchedPinPMode = NO;
	}
	glEnable(GL_DEPTH_TEST);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	float depth = 0.0;

	
	glPushMatrix();
	glLoadIdentity();
	if (openGLTextureRemote != nil){
		GLenum targetRemote = CVOpenGLTextureGetTarget(openGLTextureRemote);
		GLint name = CVOpenGLTextureGetName(openGLTextureRemote);
		GLfloat topLeft[2], topRight[2], bottomRight[2], bottomLeft[2];
		CVOpenGLTextureGetCleanTexCoords(openGLTextureRemote, bottomLeft, bottomRight, topRight, topLeft);
		
		// drawing the remote texture
		glEnable(targetRemote);
		glBindTexture(targetRemote, name);

		
		if (displayState == XM_DISPLAY_LOCAL_AND_REMOTE_VIDEO){
			Placement remoteVideoPlacement = currentPinPMode->remoteVideoPlacement;
			glPushMatrix();
			glTranslatef(remoteVideoPlacement.position.x, remoteVideoPlacement.position.y, remoteVideoPlacement.position.z);
			glScalef(remoteVideoPlacement.scaling.x, remoteVideoPlacement.scaling.y, remoteVideoPlacement.scaling.z);
			glRotatef(-remoteVideoPlacement.rotationAngle, remoteVideoPlacement.rotationAxis.x, remoteVideoPlacement.rotationAxis.y, remoteVideoPlacement.rotationAxis.z);
		}
		#ifdef __ANTIALIASED_POLY__
			glEnable( GL_POLYGON_OFFSET_FILL );
			glPolygonOffset( 1.0, 1.0 );
		#endif
		
		glScaled(videoWidth/videoHeight, 1.0, 1.0);
		[self _drawPolygon:depth bottomLeft:bottomLeft bottomRight:bottomRight topRight:topRight topLeft:topLeft];
		
		#ifdef __ANTIALIASED_POLY__
			glDisable( GL_POLYGON_OFFSET_FILL );
			glEnable( GL_BLEND );
				glEnable( GL_LINE_SMOOTH );
					glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
					glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
					[self _drawPolygon:depth bottomLeft:bottomLeft bottomRight:bottomRight topRight:topRight topLeft:topLeft];
					glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
				glDisable( GL_LINE_SMOOTH );
			glDisable( GL_BLEND );
		#endif
				
		if (displayState == XM_DISPLAY_LOCAL_AND_REMOTE_VIDEO){
			glPopMatrix();
			if (currentPinPMode->remoteVideoPlacement.isReflected){
				Placement remoteVideoPlacement = (*currentPinPMode).remoteVideoPlacement;
				glPushMatrix();
				glTranslatef(remoteVideoPlacement.position.x, -remoteVideoPlacement.position.y - remoteVideoPlacement.scaling.y * 0.25 + 0.1, remoteVideoPlacement.position.z);
				glScalef(remoteVideoPlacement.scaling.x, - remoteVideoPlacement.scaling.y * 0.5 , remoteVideoPlacement.scaling.z);
				glRotatef(-remoteVideoPlacement.rotationAngle, remoteVideoPlacement.rotationAxis.x, remoteVideoPlacement.rotationAxis.y, remoteVideoPlacement.rotationAxis.z);
				
#ifdef __ANTIALIASED_POLY__
				glEnable( GL_POLYGON_OFFSET_FILL );
				glPolygonOffset( 1.0, 1.0 );
#endif
				glScaled(videoWidth/videoHeight, 1.0, 1.0);
				[self _drawPolygon:depth bottomLeft:bottomLeft bottomRight:bottomRight topRight:topRight topLeft:topLeft];
				
				glClear (GL_DEPTH_BUFFER_BIT);
				glPushAttrib (0xffffffff);
				
				/* Create imperfect reflector effect by blending a
					mirror with a gradient over the reflected scene with alpha < 1 */
				glEnable (GL_BLEND);				
				glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
					glBegin(GL_QUADS);
						glColor4f (0., 0., 0., 0.8);
						glVertex3f(-1, -1, depth);
						glColor4f (0., 0., 0., 1.0);
						glVertex3f(-1, 1, depth);
						glVertex3f(1, 1, depth);
						glColor4f (0., 0., 0., 0.8);
						glVertex3f(1, -1, depth);
					glEnd();
				glDisable (GL_BLEND);
				
#ifdef __ANTIALIASED_POLY__
				glDisable( GL_POLYGON_OFFSET_FILL );
				glEnable( GL_BLEND );
					glEnable( GL_LINE_SMOOTH );
						glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
						glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
						[self _drawPolygon:0.0 bottomLeft:bottomLeft bottomRight:bottomRight topRight:topRight topLeft:topLeft];
						glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
					glDisable( GL_LINE_SMOOTH );
				glDisable( GL_BLEND );
#endif
				glPopAttrib();
				glPopMatrix();
			}
			
		}
		
		glDisable(targetRemote);
	}
	
	if (openGLTextureLocal != nil){
		GLenum targetLocal = CVOpenGLTextureGetTarget(openGLTextureLocal);
		GLint name = CVOpenGLTextureGetName(openGLTextureLocal);
		GLfloat topLeft[2], topRight[2], bottomRight[2], bottomLeft[2];
		CVOpenGLTextureGetCleanTexCoords(openGLTextureLocal, bottomLeft, bottomRight, topRight, topLeft);

		// drawing the local texture
		glEnable(targetLocal);
		glBindTexture(targetLocal, name);
		
		if (displayState == XM_DISPLAY_LOCAL_AND_REMOTE_VIDEO){
			Placement localVideoPlacement = (*currentPinPMode).localVideoPlacement;
			glPushMatrix();
			glTranslatef(localVideoPlacement.position.x, localVideoPlacement.position.y, localVideoPlacement.position.z);
			glScalef(localVideoPlacement.scaling.x, localVideoPlacement.scaling.y, localVideoPlacement.scaling.z);
			glRotatef(-localVideoPlacement.rotationAngle, localVideoPlacement.rotationAxis.x, localVideoPlacement.rotationAxis.y, localVideoPlacement.rotationAxis.z);
		
		}
		#ifdef __ANTIALIASED_POLY__
		if (currentPinPMode != &classicPinP){
			glEnable( GL_POLYGON_OFFSET_FILL );
			glPolygonOffset( 1.0, 1.0 );
		}
		#endif
		glScaled(videoWidth/videoHeight, 1.0, 1.0); 
		[self _drawPolygon:depth bottomLeft:bottomLeft bottomRight:bottomRight topRight:topRight topLeft:topLeft];
		
		#ifdef __ANTIALIASED_POLY__
		if (currentPinPMode != &classicPinP){
			glDisable( GL_POLYGON_OFFSET_FILL );
			glEnable( GL_BLEND );
			glEnable( GL_LINE_SMOOTH );
			glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
			glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
			[self _drawPolygon:depth bottomLeft:bottomLeft bottomRight:bottomRight topRight:topRight topLeft:topLeft];
			glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
			glDisable( GL_LINE_SMOOTH );
			glDisable( GL_BLEND );
		}
		#endif
		
		if (displayState == XM_DISPLAY_LOCAL_AND_REMOTE_VIDEO){
			if (currentPinPMode == &classicPinP){ //draw the border around local video area
				glEnable( GL_POLYGON_OFFSET_LINE );
				glDisable(targetLocal);
				glPolygonOffset( -1.0, -1.0 );
				glEnable( GL_LINE_SMOOTH );
				glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
					glBegin(GL_QUADS);
						glColor4f(1.0, 1.0, 1.0, 1.0);
						glVertex3f(-1, -1, depth);
						glVertex3f(-1, 1, depth);
						glVertex3f(1, 1, depth);
						glVertex3f(1, -1, depth);
					glEnd();
				glDisable( GL_LINE_SMOOTH );
				glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
				glEnable(targetLocal);
				glDisable( GL_POLYGON_OFFSET_LINE );
			}
			glPopMatrix();


			if (currentPinPMode->localVideoPlacement.isReflected){
				Placement localVideoPlacement = (*currentPinPMode).localVideoPlacement;
				glPushMatrix();
				glTranslatef(localVideoPlacement.position.x, -localVideoPlacement.position.y - localVideoPlacement.scaling.y * 0.25 + 0.1, localVideoPlacement.position.z);
				glScalef(localVideoPlacement.scaling.x, - localVideoPlacement.scaling.y * 0.5 , localVideoPlacement.scaling.z);
				glRotatef(-localVideoPlacement.rotationAngle, localVideoPlacement.rotationAxis.x, localVideoPlacement.rotationAxis.y, localVideoPlacement.rotationAxis.z);

				#ifdef __ANTIALIASED_POLY__
					glEnable( GL_POLYGON_OFFSET_FILL );
					glPolygonOffset( 1.0, 1.0 );
				#endif
				glScaled(videoWidth/videoHeight, 1.0, 1.0);
[self _drawPolygon:depth bottomLeft:bottomLeft bottomRight:bottomRight topRight:topRight topLeft:topLeft];

				
				glClear (GL_DEPTH_BUFFER_BIT);
				glPushAttrib (0xffffffff);

				/* Create imperfect reflector effect by blending a
				   mirror with a gradient over the reflected scene with alpha < 1 */
				glEnable (GL_BLEND);

				glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
				
				glBegin(GL_QUADS);
					glColor4f (0., 0., 0., 0.8);
					glVertex3f(-1, -1, depth);
					glColor4f (0., 0., 0., 1.0);
					glVertex3f(-1, 1, depth);
					glVertex3f(1, 1, depth);
					glColor4f (0., 0., 0., 0.8);
					glVertex3f(1, -1, depth);
				glEnd();

				glDisable (GL_BLEND);
				
				#ifdef __ANTIALIASED_POLY__
					glDisable( GL_POLYGON_OFFSET_FILL );
					glEnable( GL_BLEND );
					glEnable( GL_LINE_SMOOTH );
					glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
					glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
					[self _drawPolygon:0.0 bottomLeft:bottomLeft bottomRight:bottomRight topRight:topRight topLeft:topLeft];

					glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
					glDisable( GL_LINE_SMOOTH );
					glDisable( GL_BLEND );
				#endif
				glPopAttrib();
				glPopMatrix();
			}
		
		}
		
		glDisable(targetLocal);

	}
		
	
	glColor3f(1.0f, 1.0f, 1.0f);
	glPopMatrix();
	
	// Flush the buffer to let the changes propagate to the screen
	glFlush();
}


#pragma mark -
#pragma mark Mouse Tracking
- (void)_removeTrackingRect{
	if ( trackingRect != -1 )
	{
		[self removeTrackingRect:trackingRect];
		trackingRect = -1;
		[self _stopTimer];
	}
	
}

- (void)_setTrackingRect{
	if (trackingRect == -1){
		NSRect tr = [self bounds];
		isMouseInView = NSPointInRect([[self window] convertScreenToBase:[NSEvent mouseLocation]], tr);		
		trackingRect = [self addTrackingRect:tr owner:self userData:nil assumeInside:isMouseInView];	
		[self _startTimer];
	}
}

- (void)_resetTrackingRect{
	if (shouldDisplayOSD){
		[self _removeTrackingRect];
		[self _setTrackingRect];		
	}
}

#pragma mark -
#pragma mark Private Methods

- (void)_displayTimeout:(NSTimer*)t{
	if (shouldDisplayOSD){
		NSPoint mouseLoc = [[self window] convertScreenToBase:[NSEvent mouseLocation]];
		mouseLoc = [self convertPoint:[NSEvent mouseLocation] fromView:nil];
		
		static int hitCount = 0;
		
		if (!NSEqualPoints(mouseLoc,lastMouseLocation)){
			hitCount= 0;
			if (isMouseInView || fullscreen){
				if (!isOSDDisplayed) {
					[self _displayOSDWithSize:(fullscreen ? OSD_LARGE : OSD_SMALL)];
				}
			}
		}
		else{
			hitCount++;
			if (hitCount == 3){	//mouse not moved for 3 * timerPeriod
				if (isOSDDisplayed) {
				
					NSRect viewRect = [osd osdRect];
					NSPoint mouseLocation = [[self window] mouseLocationOutsideOfEventStream];
					mouseLocation = [self convertPoint:mouseLocation fromView:nil];
					mouseLocation = [osd convertPoint:mouseLocation fromView:nil];
					
					if (!NSPointInRect(mouseLocation,viewRect)){ //if we are outside the OSD
						[osdControllerWindow closeWithEffect:FadeOutEffect];
						isOSDDisplayed = NO;
					}

				}
				hitCount = 0;
			}
		}
		lastMouseLocation = mouseLoc;
	}
}


- (void)_frameDidChange:(NSNotification *)notif{
	[self _resetTrackingRect];
}

- (void)_windowWillMiniaturize:(NSNotification *)notif
{
	[osdControllerWindow closeWithEffect:NoEffect];
	isOSDDisplayed = NO;
	isMiniaturized = YES;
	[self _stopTimer];
	[self display];
}

- (void)_windowWillClose:(NSNotification *)notif{
	[osdControllerWindow closeWithEffect:NoEffect];
	[self _stopTimer];
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)proposedFrameSize{
	[self mouseExited:[NSApp currentEvent]];
	return proposedFrameSize;
}


- (void)_windowWillMove:(NSNotification *)notif{
	//[osdControllerWindow closeWithEffect:NoEffect];
	[self mouseExited:[NSApp currentEvent]];
}

- (void)_windowDidDeminiaturize:(NSNotification *)notif
{
	isMiniaturized = NO;
	//restart display timer...
	[self _startTimer];
}

- (void)_didStartSelectedInputDeviceChange:(NSNotification *)notif
{
	if(displayState == XM_DISPLAY_LOCAL_VIDEO || displayState == XM_DISPLAY_LOCAL_AND_REMOTE_VIDEO)
	{
		isBusy = YES;
		
		[busyIndicator startAnimation:self];
		[busyIndicator setHidden:NO];
		
		[self display];
	}
}

- (void)_didChangeSelectedInputDevice:(NSNotification *)notif
{
	if((displayState == XM_DISPLAY_LOCAL_VIDEO || displayState == XM_DISPLAY_LOCAL_AND_REMOTE_VIDEO) && isBusy == YES)
	{
		isBusy = NO;
		
		[busyIndicator setHidden:YES];
		[busyIndicator stopAnimation:self];
	}
}

- (void)_displayOSDWithSize:(int)size{
	//NSLog(@"display OSD");
	isOSDDisplayed = YES;
	isMouseInView = YES;
	if (osdControllerWindow) [osdControllerWindow release];
	
	NSPoint viewOrigin = [self bounds].origin;
	viewOrigin = [self convertPoint:viewOrigin toView:[[self window] contentView]];
	
	//convert origin to screen coordinates;
	viewOrigin = [[self window] convertBaseToScreen:viewOrigin];

	NSRect viewRect = [self frame];
	viewRect.origin = viewOrigin;

	if (!osd){
		//Choose the right OSD type
		XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];	
		BOOL isVideoEnabled = [[[preferencesManager locations] objectAtIndex:[preferencesManager indexOfActiveLocation]] enableVideo]; 
		if (isVideoEnabled)
			osd = [[XMInCallOSD alloc] initWithFrame:[self frame] delegate:self andSize:size];
		else
			osd = [[XMAudioOnlyOSD alloc] initWithFrame:[self frame] delegate:self andSize:size];
	}
	else
	{
		[osd setFrame:[self frame]];
	}
	[osd setOSDSize:size];
	osdControllerWindow = [[XMOnScreenControllerWindow controllerWindowWithContollerView:osd parentRect:viewRect fullscreen:fullscreen] retain];
	[osdControllerWindow openWithEffect:FadeInEffect];
}

- (void)_startTimer{
	if (OSDDisplayTimer) [self _stopTimer];
	
	if (shouldDisplayOSD){
		OSDDisplayTimer = [[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)0.5 target:self selector:@selector(_displayTimeout:) userInfo:nil repeats:YES] retain];
	}
}

- (void)_stopTimer{
	if (OSDDisplayTimer){
		[OSDDisplayTimer invalidate];
		[OSDDisplayTimer release];
		OSDDisplayTimer = nil;		
	}
}

- (void)_callCleared:(NSNotification*)notif{
	if (fullscreen){
		[self goWindowedMode];
		if ([osd respondsToSelector:@selector(setFullscreenState:)]){
			[(XMInCallOSD*)osd setFullscreenState:NO];
		}
	}
}



#pragma mark -
#pragma mark OSD Actions
- (void)mute{
// The following code does NOT work as it should, so a workaround was found
//	XMAudioManager *audioManager = [XMAudioManager sharedInstance];
//	[audioManager setMutesOutputVolume:YES];

	XMAudioManager *audioManager = [XMAudioManager sharedInstance];
	
	volume = (unsigned)[audioManager inputVolume];
	
	if([audioManager setInputVolume:0])
	{
	}

}

- (void)unmute{
//See comments on -(void)mute
//	XMAudioManager *audioManager = [XMAudioManager sharedInstance];
//	[audioManager setMutesOutputVolume:NO];

	XMAudioManager *audioManager = [XMAudioManager sharedInstance];
		
	if(![audioManager setInputVolume:volume])
	{
	}
	
}

- (void)goFullScreen{
	NSRect screenRect;
	
	//close inspectors because they interfere with the OSD
	//this could be solved in a more elegant way
	[XMInspectorController closeAllInspectors];
	
	windowedSize = [self frame].size;
	
	screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
	
	[NSMenu setMenuBarVisible:NO];
	fullscreenWindow = [[XMEventAwareWindow alloc] initWithContentRect:screenRect 
													styleMask:NSBorderlessWindowMask 
													backing:NSBackingStoreBuffered 
													defer:NO
													screen:[[NSScreen screens] objectAtIndex:0]];
	[fullscreenWindow setDelegate:fullscreenWindow];
	[fullscreenWindow setLevel:NSScreenSaverWindowLevel];

	windowedSuperview = [self superview];
	
	fullscreen = YES;
	if (isOSDDisplayed && osdControllerWindow){
		//[osdControllerWindow closeWithEffect:NoEffect];
		[self mouseExited:[NSApp currentEvent]];
		[osd setOSDSize:OSD_LARGE];
	}
	else
		[osd setOSDSize:OSD_LARGE];

	[fullscreenWindow setContentView:self];
	[fullscreenWindow makeKeyAndOrderFront:nil];
	[self becomeFirstResponder];
	//[osdControllerWindow openWithEffect:FadeInEffect];

}

- (void)goWindowedMode{
	if (osdControllerWindow) [osdControllerWindow closeWithEffect:NoEffect];
	isOSDDisplayed = NO;
	
	[NSMenu setMenuBarVisible:YES];

	[fullscreenWindow setContentView:nil];
    [fullscreenWindow orderOut:self];

	[windowedSuperview addSubview:self];
	fullscreen = NO;
	[fullscreenWindow release];
	fullscreenWindow = nil;
	
	//Reset the view's size, otherwise the OSD will be placed in strange places...
	NSRect myFrame = [self frame];
	myFrame.size = windowedSize;
	[self setFrame:myFrame];
}

- (void)togglePictureInPicture{
	if (displayState == XM_DISPLAY_LOCAL_AND_REMOTE_VIDEO)
		displayState = XM_DISPLAY_REMOTE_VIDEO;
	else
		displayState = XM_DISPLAY_LOCAL_AND_REMOTE_VIDEO;
		
	switchedPinPMode = YES;
	pinp = !pinp;
}


- (void)nextPinPModeAnimating:(BOOL)animating{
	animating = YES;
	//if PinP is not yet enabled, enable it
	if (displayState != XM_DISPLAY_LOCAL_AND_REMOTE_VIDEO){
		displayState = XM_DISPLAY_LOCAL_AND_REMOTE_VIDEO;
		
		if ([osd respondsToSelector:@selector(setPinPState:)]){
			//update the OSD button
			[(XMInCallOSD*)osd setPinPState:YES];
		}
	}
	temporaryScene = *currentPinPMode;
	
	if (pinp){
		initialPinPMode = currentPinPMode;
	}
	else
	{
		initialPinPMode = &noPinPScene;
		temporaryScene = noPinPScene;
	}
	
	//turn off reflection, if present
	if (temporaryScene.localVideoPlacement.isReflected) temporaryScene.localVideoPlacement.isReflected = NO;
	if (temporaryScene.remoteVideoPlacement.isReflected) temporaryScene.remoteVideoPlacement.isReflected = NO;
	
	if (animating){
		if (sceneAnimation != nil){
			if ([sceneAnimation isAnimating]) [sceneAnimation stopAnimation];
			[sceneAnimation release];
			sceneAnimation = nil;
		}
		sceneAnimation = [[NSAnimation alloc] initWithDuration:0.7 animationCurve:NSAnimationEaseInOut];
		[sceneAnimation setAnimationBlockingMode:NSAnimationNonblocking];
		[sceneAnimation setDelegate:self];
		
		float i;
		float step = 1.0/XM_ANIMATION_STEPS;
		for (i = 0; i <= 1; i += step)
		{
			[sceneAnimation addProgressMark:i];
		}
				
		if(currentPinPMode == &classicPinP){
			targetPinPMode = &ichatPinP;
		}
		else if (currentPinPMode == &ichatPinP){
			targetPinPMode = &sideBySidePinP;
		}
		else if (currentPinPMode == &sideBySidePinP){
			targetPinPMode = &classicPinP;
		}
		
		currentPinPMode = &temporaryScene;
		[sceneAnimation startAnimation];
	}
	else
	{
		if(currentPinPMode == &classicPinP){
			currentPinPMode = &ichatPinP;
		}
		else if (currentPinPMode == &ichatPinP){
			currentPinPMode = &sideBySidePinP;
		}
		else if (currentPinPMode == &sideBySidePinP){
			currentPinPMode = &classicPinP;
		}
	}

	switchedPinPMode = YES;
	pinp = YES;
}

- (void)hangup{
	if (fullscreen){
		[self goWindowedMode];
		if ([osd respondsToSelector:@selector(setFullscreenState:)]){
			[(XMInCallOSD*)osd setFullscreenState:NO];
		}
	}
	else
	{
		if (osdControllerWindow) [osdControllerWindow closeWithEffect:NoEffect];
		isOSDDisplayed = NO;
	}
	

	[[XMCallManager sharedInstance] clearActiveCall];
	[self setShouldDisplayOSD:NO];
}

- (void)showInspector{
	if (fullscreen){
		[self goWindowedMode];
		if ([osd respondsToSelector:@selector(setFullscreenState:)]){
			[(XMInCallOSD*)osd setFullscreenState:NO];
		}
	}
	[[NSApp delegate] showInspector:self];
}

- (void)showTools{
	if (fullscreen){
		[self goWindowedMode];
		if ([osd respondsToSelector:@selector(setFullscreenState:)]){
			[(XMInCallOSD*)osd setFullscreenState:NO];
		}
	}
	[[NSApp delegate] showTools:self];
}


#pragma mark -

- (void)_drawPolygon:(GLfloat)depth bottomLeft:(GLfloat*)bottomLeft bottomRight:(GLfloat*)bottomRight topRight:(GLfloat*)topRight topLeft:(GLfloat*)topLeft{
	glBegin(GL_QUADS);
		glTexCoord2fv(bottomLeft); glVertex3f(-1, -1, depth);
		glTexCoord2fv(topLeft); glVertex3f(-1, 1, depth);
		glTexCoord2fv(topRight); glVertex3f(1, 1, depth);
		glTexCoord2fv(bottomRight); glVertex3f(1, -1, depth);
	glEnd();
}

#pragma mark -
#pragma mark Animation

- (void)animation:(NSAnimation *)animation didReachProgressMark:(NSAnimationProgress)progress
{
    //set up a linear interpolation of all values
	//camera
	temporaryScene.camera.eye.x +=  (targetPinPMode->camera.eye.x - initialPinPMode->camera.eye.x)/XM_ANIMATION_STEPS;
	temporaryScene.camera.eye.y +=  (targetPinPMode->camera.eye.y - initialPinPMode->camera.eye.y)/XM_ANIMATION_STEPS;
	temporaryScene.camera.eye.z +=  (targetPinPMode->camera.eye.z - initialPinPMode->camera.eye.z)/XM_ANIMATION_STEPS;
	temporaryScene.camera.sceneCenter.x +=  (targetPinPMode->camera.sceneCenter.x - initialPinPMode->camera.sceneCenter.x)/XM_ANIMATION_STEPS;
	temporaryScene.camera.sceneCenter.y +=  (targetPinPMode->camera.sceneCenter.y - initialPinPMode->camera.sceneCenter.y)/XM_ANIMATION_STEPS;
	temporaryScene.camera.sceneCenter.z +=  (targetPinPMode->camera.sceneCenter.z - initialPinPMode->camera.sceneCenter.z)/XM_ANIMATION_STEPS;
	
	//local video
	temporaryScene.localVideoPlacement.position.x +=  (targetPinPMode->localVideoPlacement.position.x - initialPinPMode->localVideoPlacement.position.x)/XM_ANIMATION_STEPS;
	temporaryScene.localVideoPlacement.position.y +=  (targetPinPMode->localVideoPlacement.position.y - initialPinPMode->localVideoPlacement.position.y)/XM_ANIMATION_STEPS; 
	temporaryScene.localVideoPlacement.position.z +=  (targetPinPMode->localVideoPlacement.position.z - initialPinPMode->localVideoPlacement.position.z)/XM_ANIMATION_STEPS;
	temporaryScene.localVideoPlacement.scaling.x += (targetPinPMode->localVideoPlacement.scaling.x - initialPinPMode->localVideoPlacement.scaling.x)/XM_ANIMATION_STEPS;
	temporaryScene.localVideoPlacement.scaling.y += (targetPinPMode->localVideoPlacement.scaling.y - initialPinPMode->localVideoPlacement.scaling.y)/XM_ANIMATION_STEPS;
	temporaryScene.localVideoPlacement.scaling.z += (targetPinPMode->localVideoPlacement.scaling.z - initialPinPMode->localVideoPlacement.scaling.z)/XM_ANIMATION_STEPS;

	temporaryScene.localVideoPlacement.rotationAngle +=  (targetPinPMode->localVideoPlacement.rotationAngle - initialPinPMode->localVideoPlacement.rotationAngle)/XM_ANIMATION_STEPS;
	
	//remote video
	temporaryScene.remoteVideoPlacement.position.x +=  (targetPinPMode->remoteVideoPlacement.position.x - initialPinPMode->remoteVideoPlacement.position.x)/XM_ANIMATION_STEPS;
	temporaryScene.remoteVideoPlacement.position.y +=  (targetPinPMode->remoteVideoPlacement.position.y - initialPinPMode->remoteVideoPlacement.position.y)/XM_ANIMATION_STEPS; 
	temporaryScene.remoteVideoPlacement.position.z +=  (targetPinPMode->remoteVideoPlacement.position.z - initialPinPMode->remoteVideoPlacement.position.z)/XM_ANIMATION_STEPS;
	temporaryScene.remoteVideoPlacement.scaling.x += (targetPinPMode->remoteVideoPlacement.scaling.x - initialPinPMode->remoteVideoPlacement.scaling.x)/XM_ANIMATION_STEPS;
	temporaryScene.remoteVideoPlacement.scaling.y += (targetPinPMode->remoteVideoPlacement.scaling.y - initialPinPMode->remoteVideoPlacement.scaling.y)/XM_ANIMATION_STEPS;
	temporaryScene.remoteVideoPlacement.scaling.z += (targetPinPMode->remoteVideoPlacement.scaling.z - initialPinPMode->remoteVideoPlacement.scaling.z)/XM_ANIMATION_STEPS;
	
	temporaryScene.remoteVideoPlacement.rotationAngle +=  (targetPinPMode->remoteVideoPlacement.rotationAngle - initialPinPMode->remoteVideoPlacement.rotationAngle)/XM_ANIMATION_STEPS;

	switchedPinPMode = YES;
}

- (void)animationDidEnd:(NSAnimation *)animation
{
	currentPinPMode = targetPinPMode;
}

- (void)animationDidStop:(NSAnimation *)animation // executes if the animation is aborted somehow
{
	currentPinPMode = targetPinPMode;
}

#pragma mark -
#pragma mark Event Handling

- (void)keyDown:(NSEvent *) event
{
    NSString *characters;
    characters = [event characters];
	
    unichar character;
    character = [characters characterAtIndex: 0];
	
	if (character == 27 && fullscreen){
		[self goWindowedMode];
		if ([osd respondsToSelector:@selector(setFullscreenState:)]){
			[(XMInCallOSD*)osd setFullscreenState:NO];
		}
	}
	if (character == NSDeleteCharacter || character == NSBackspaceCharacter){
		[self hangup];
	}

}

- (void)mouseDown:(NSEvent *)theEvent{
	struct Vector3 pinpPos = currentPinPMode->localVideoPlacement.position;
	//conversion to view coordinates
	float videoCenterX = (pinpPos.x + 1.0)/2.0 * [self bounds].size.width;
	float videoCenterY = (pinpPos.y + 1.0)/2.0 * [self bounds].size.height;
	
	downPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	downPoint = [self convertPoint:downPoint toView:self];
	
	downPoint.x -= videoCenterX;
	downPoint.y -= videoCenterY;
	
	if (displayState == XM_DISPLAY_NO_VIDEO || displayState == XM_DISPLAY_LOCAL_VIDEO){
		[[NSApp delegate] showTools:self];
	}
}

- (void)mouseDragged:(NSEvent *)theEvent{
	if (displayState == XM_DISPLAY_LOCAL_AND_REMOTE_VIDEO && currentPinPMode == &classicPinP){
		NSPoint transformedPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		transformedPoint = [self convertPoint:transformedPoint toView:self];
				
		struct Vector3 pinpPos = currentPinPMode->localVideoPlacement.position;
		//conversion to view coordinates
		float videoWidth = (currentPinPMode->localVideoPlacement.scaling.x * [self bounds].size.width);
		float videoHeight = (currentPinPMode->localVideoPlacement.scaling.y * [self bounds].size.height);
		float videoCenterX = (pinpPos.x + 1.0)/2.0 * [self bounds].size.width;
		float videoCenterY = (pinpPos.y + 1.0)/2.0 * [self bounds].size.height;
		
		NSRect pinpVideoRect = NSMakeRect(videoCenterX - videoWidth/2.0, videoCenterY - videoHeight/2.0, videoWidth, videoHeight);		
		
	  if (NSPointInRect(transformedPoint, pinpVideoRect)){
			//back to ogl coordinates
		  float posX = 2.0 * ((transformedPoint.x - downPoint.x) / [self bounds].size.width) - 1.0;
		  float posY = 2.0 * ((transformedPoint.y - downPoint.y) / [self bounds].size.height) - 1.0 ;
		  		  
		  currentPinPMode->localVideoPlacement.position.x = posX;
		  currentPinPMode->localVideoPlacement.position.y = posY;
		}
		
	}
}
- (void)mouseEntered:(NSEvent *)theEvent{
	if (isOSDDisplayed || !shouldDisplayOSD) return;	
	[self _displayOSDWithSize:(fullscreen ? OSD_LARGE : OSD_SMALL)]; 

}

- (void)mouseExited:(NSEvent *)theEvent{
	if (isOSDDisplayed){
		NSRect viewRect = [osd osdRect];
		//avoid osd blinking by enlarging and repositioning the tracking rect
		viewRect.size.height += 2;
		viewRect.size.width += 2;
		viewRect.origin.x -= 1;
		
		NSPoint mouseLocation = [theEvent locationInWindow];
		mouseLocation = [self convertPoint:mouseLocation fromView:nil];
		mouseLocation = [osd convertPoint:mouseLocation fromView:nil];
		
		if (NSPointInRect(mouseLocation,viewRect)){ //if we left for the OSD
			return;
		}
		else
		{
			isMouseInView = NO;
			isOSDDisplayed = NO;
			[osdControllerWindow closeWithEffect:FadeOutEffect];
		}
	}
}

#pragma mark -
#pragma mark Notifications
- (void)_preferencesDidChange:(NSNotification*)notif{
	if (osd){
		[osd release];
		osd = nil;
	}
}


@end
