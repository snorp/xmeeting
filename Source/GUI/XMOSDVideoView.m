/*
 * $Id: XMOSDVideoView.m,v 1.9 2006/03/23 10:04:49 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Ivan Guajana. All rights reserved.
 */

#import "XMOSDVideoView.h"

#import <OpenGL/OpenGL.h>
#import <GLUT/glut.h>
#import <QuartzCore/QuartzCore.h>

#import "XMApplicationController.h"
#import "XMPreferencesManager.h"
#import "XMWindow.h"

#import "XMOnScreenControllerWindow.h"
#import "XMOnScreenControllerView.h"
#import "XMInCallOSD.h"
#import "XMAudioOnlyOSD.h"

#define XM_DISPLAY_NOTHING 0
#define XM_DISPLAY_VIDEO 1
#define XM_DISPLAY_NO_VIDEO 2

#define XM_ANIMATION_STEPS 60.0

#define __ANTIALIASED_POLY__ 1


@interface XMOSDVideoView (PrivateMethods)

- (void)_init;

//Animating
- (void)animation:(NSAnimation *)animation didReachProgressMark:(NSAnimationProgress)progress;
- (void)animationDidEnd:(NSAnimation *)animation;
- (void)animationDidStop:(NSAnimation *)animation;

// Notifications
- (void)_windowWillMiniaturize:(NSNotification *)notif;
- (void)_windowDidDeminiaturize:(NSNotification *)notif;
- (void)_frameDidChange:(NSNotification *)notif;

//Drawing
- (void)_drawPolygon:(GLfloat)depth bottomLeft:(GLfloat*)bottomLeft
		 bottomRight:(GLfloat*)bottomRight topRight:(GLfloat*)topRight
			 topLeft:(GLfloat*)topLeft mirrored:(BOOL)mirrored;

- (void)_displayOSD:(XMOpeningEffect)openingEffect;
- (void)_hideOSD:(XMClosingEffect)closingEffect;
- (void)_resetOSDTrackingRect;

@end

@implementation XMOSDVideoView

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
	
	NSOpenGLPixelFormat *openGLPixelFormat = [videoManager openGLPixelFormat];
	openGLContext = [[NSOpenGLContext alloc] initWithFormat:openGLPixelFormat shareContext:[videoManager openGLContext]];
	displaySize = NSMakeSize(0, 0);
	
	long swapInterval = 1;
	[openGLContext setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];
	
	videoImageRep = nil;
	isMiniaturized = NO;
	
	noVideoImage = nil;
	
	osd = nil;
	osdControllerWindow = nil;
	osdDisplayMode = XMOSDDisplayMode_NoOSD;
	doesShowOSD = NO;
	osdTrackingRect = 0;
	osdOpeningEffect = XMOpeningEffect_NoEffect;
	osdClosingEffect = XMClosingEffect_NoEffect;
	
	isFullScreen = NO;
	
	// setting up the view scenes
	noPinP.remoteVideoPlacement = XMMakePlacement(XMMakeVector3(0.0,0.0,0.0), NO_SCALING, ROTATION_AXIS_Y, (GLfloat)0.0);	
	noPinP.camera = XMMakeCamera(XMMakeVector3(0.0, 0.0, 3.8), POSITION_CENTERED, ROTATION_AXIS_Y);
	
	classicPinP.localVideoPlacement = XMMakePlacement(XMMakeVector3(0.65, -0.5, 0.1), XMMakeVector3(0.25, 0.25, 1.0), ROTATION_AXIS_Y, (GLfloat)0.0);
	classicPinP.remoteVideoPlacement = XMMakePlacement(XMMakeVector3(0.0,0.0,0.0), NO_SCALING, ROTATION_AXIS_Y, (GLfloat)0.0);	
	classicPinP.camera = XMMakeCamera(XMMakeVector3(0.0,0.0,3.8), POSITION_CENTERED, ROTATION_AXIS_Y);
	
	sideBySidePinP.localVideoPlacement = XMMakePlacement(XMMakeVector3(0.65, 0.0, 0.0), XMMakeVector3(0.48, 0.48, 1.0), ROTATION_AXIS_Y, (GLfloat)0.0);
	sideBySidePinP.remoteVideoPlacement = XMMakePlacement(XMMakeVector3(-0.65, 0.0, 0.0), XMMakeVector3(0.48, 0.48, 1.0), ROTATION_AXIS_Y, (GLfloat)0.0);	
	sideBySidePinP.camera = XMMakeCamera(XMMakeVector3(0.0,0.0,3.8), POSITION_CENTERED, ROTATION_AXIS_Y);
	
	roomPinP.localVideoPlacement = XMMakePlacement(XMMakeVector3(0.6, 0.34, -3.0), XMMakeVector3(0.45, 0.45, 1.0), ROTATION_AXIS_Y, (GLfloat)25.0);
	roomPinP.localVideoPlacement.isReflected = YES;
	roomPinP.remoteVideoPlacement = XMMakePlacement(XMMakeVector3(-0.6, 0.34, -3.0), XMMakeVector3(0.45, 0.45, 1.0), ROTATION_AXIS_Y, (GLfloat)-25.0);
	roomPinP.remoteVideoPlacement.isReflected = YES;
	roomPinP.camera = XMMakeCamera(XMMakeVector3(0.0, 1.0, 1.1), XMMakeVector3(0, 0, -3.0), ROTATION_AXIS_Y);

	currentPinPMode = &noPinP;
	initialPinPMode = currentPinPMode;
	switchedPinPMode = NO;
	
	isLocalVideoMirrored = NO;
}

- (void)dealloc
{	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[openGLContext release];
	
	[noVideoImage release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Overriden NSView methods
	
- (void)viewDidMoveToWindow
{
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter removeObserver:self name:NSViewFrameDidChangeNotification object:nil];
	
	if([self window] != nil)
	{
		[notificationCenter addObserver:self selector:@selector(_frameDidChange:)
								   name:NSViewFrameDidChangeNotification object:[[self window] contentView]];
		
		[self _frameDidChange:nil];
	}
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)drawRect:(NSRect)rect
{
	if(displayStatus == XM_DISPLAY_VIDEO)
	{
		// if we have to redraw, we force an instant update of the window
		// to prevent flickering
		XMVideoManager *videoManager = [XMVideoManager sharedInstance];
		[videoManager forceRenderingForView:self];
	}
	else if(displayStatus == XM_DISPLAY_NO_VIDEO && noVideoImage != nil)
	{
		NSSize size = [noVideoImage size];
		[noVideoImage drawInRect:[self bounds] fromRect:NSMakeRect(0, 0, size.width, size.height)
					   operation:NSCompositeCopy fraction:1.0];
	}
	else
	{
		NSRectFill(rect);
	}
	
	if(osdDisplayMode == XMOSDDisplayMode_AlwaysVisible && doesShowOSD == NO)
	{
		[self _displayOSD:osdOpeningEffect];
	}
}

- (BOOL)isOpaque
{
	return YES;
}

#pragma mark -
#pragma mark public Methods

- (void)startDisplayingVideo
{
	if(displayStatus == XM_DISPLAY_VIDEO)
	{
		return;
	}
	
	[self stopDisplayingNoVideo];
	
	XMVideoManager *videoManager = [XMVideoManager sharedInstance];
	
	[openGLContext clearDrawable];
	
	[openGLContext setView:self];
	
	displayStatus = XM_DISPLAY_VIDEO;
	
	[videoManager addVideoView:self];
	
	switchedPinPMode = YES;
}

- (void)stopDisplayingVideo
{
	if(displayStatus != XM_DISPLAY_VIDEO)
	{
		return;
	}
	
	XMVideoManager *videoManager = [XMVideoManager sharedInstance];
	
	[videoManager removeVideoView:self];
	
	displayStatus = XM_DISPLAY_NOTHING;
	
	[self display];
	
	[openGLContext clearDrawable];
}

- (BOOL)doesDisplayVideo
{
	return (displayStatus == XM_DISPLAY_VIDEO);
}

- (XMPinPMode)pinpMode
{
	if(currentPinPMode == &noPinP)
	{
		return XMPinPMode_NoPinP;
	}
	else if(currentPinPMode == &classicPinP)
	{
		return XMPinPMode_Classic;
	}
	else if(currentPinPMode == &sideBySidePinP)
	{
		return XMPinPMode_SideBySide;
	}
	else if(currentPinPMode == &roomPinP)
	{
		return XMPinPMode_3D;
	}
	
	return XMPinPMode_NoPinP;
}

- (void)setPinPMode:(XMPinPMode)mode animate:(BOOL)animate
{
	if (sceneAnimation != nil)
	{
		if ([sceneAnimation isAnimating]) 
		{
			[sceneAnimation stopAnimation];
		}
		[sceneAnimation release];
		sceneAnimation = nil;
	}
	
	if(mode == XMPinPMode_NoPinP)
	{
		targetPinPMode = &noPinP;
	}
	else if(mode == XMPinPMode_Classic)
	{
		targetPinPMode = &classicPinP;
	}
	else if(mode == XMPinPMode_SideBySide)
	{
		targetPinPMode = &sideBySidePinP;
	}
	else
	{
		targetPinPMode = &roomPinP;
	}
	
	// simply return if there is nothing to change, we're not showing video
	// or no animation is to make.
	if(targetPinPMode == currentPinPMode ||
	   displayStatus != XM_DISPLAY_VIDEO ||
	   animate == NO)
	{
		currentPinPMode = targetPinPMode;
		switchedPinPMode = YES;
		return;
	}
	
	initialPinPMode = currentPinPMode;
	temporaryScene = *currentPinPMode;
	
	//turn off reflection, if present
	temporaryScene.localVideoPlacement.isReflected = NO;
	temporaryScene.remoteVideoPlacement.isReflected = NO;

	sceneAnimation = [[NSAnimation alloc] initWithDuration:0.7 animationCurve:NSAnimationEaseInOut];
	[sceneAnimation setAnimationBlockingMode:NSAnimationNonblocking];
	[sceneAnimation setDelegate:self];
		
	float i;
	float step = 1.0/XM_ANIMATION_STEPS;
	for (i = 0; i <= 1; i += step)
	{
		[sceneAnimation addProgressMark:i];
	}
		
	currentPinPMode = &temporaryScene;
	[sceneAnimation startAnimation];
	
	switchedPinPMode = YES;
}

- (void)startDisplayingNoVideo
{
	if(displayStatus == XM_DISPLAY_NO_VIDEO)
	{
		return;
	}
	
	[self stopDisplayingVideo];
	
	displayStatus = XM_DISPLAY_NO_VIDEO;
	
	[self setNeedsDisplay:YES];
}

- (void)stopDisplayingNoVideo
{
	if(displayStatus != XM_DISPLAY_NO_VIDEO)
	{
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

- (XMOSDDisplayMode)osdDisplayMode
{
	return osdDisplayMode;
}

- (void)setOSDDisplayMode:(XMOSDDisplayMode)mode
{
	osdDisplayMode = mode;
	
	if(mode == XMOSDDisplayMode_NoOSD)
	{
		[self _hideOSD:XMClosingEffect_NoEffect];
	}
	else if(mode == XMOSDDisplayMode_AutomaticallyHiding)
	{
		[self _hideOSD:osdClosingEffect];
	}
	else if(mode == XMOSDDisplayMode_AlwaysVisible)
	{
		[self _displayOSD:osdOpeningEffect];
	}
	
	[self _resetOSDTrackingRect];
}

- (XMOpeningEffect)osdOpeningEffect
{
	return osdOpeningEffect;
}

- (void)setOSDOpeningEffect:(XMOpeningEffect)effect
{
	osdOpeningEffect = effect;
}

- (XMClosingEffect)osdClosingEffect
{
	return osdClosingEffect;
}

- (void)setOSDClosingEffect:(XMClosingEffect)effect
{
	osdClosingEffect = effect;
}

- (BOOL)isFullScreen
{
	return isFullScreen;
}

- (void)setFullScreen:(BOOL)flag
{
	isFullScreen = flag;
	
	if(doesShowOSD)
	{
		[self _hideOSD:XMClosingEffect_NoEffect];
	}
	
	if(osd != nil && [osd isKindOfClass:[XMInCallOSD class]])
	{
		[(XMInCallOSD *)osd setIsFullScreen:flag];
	}
}

- (BOOL)isLocalVideoMirrored
{
	return isLocalVideoMirrored;
}

- (void)setLocalVideoMirrored:(BOOL)flag
{
	isLocalVideoMirrored = flag;
}

#pragma mark -
#pragma mark XMVideoView protocol methods

- (void)renderLocalVideo:(CVOpenGLTextureRef)localVideo didChange:(BOOL)localVideoDidChange 
			 remoteVideo:(CVOpenGLTextureRef)remoteVideo didChange:(BOOL)remoteVideoDidChange
				isForced:(BOOL)isForced
{
	if([openGLContext view] == nil)
	{
		return;
	}
	
	if(isForced == YES)
	{
		if(isMiniaturized == YES)
		{
			if(videoImageRep == nil)
			{
				CIImage *image = [[CIImage alloc] initWithCVImageBuffer:remoteVideo];
				videoImageRep = [[NSCIImageRep alloc] initWithCIImage:image];
				[image release];
			}
			
			if(videoImageRep != nil)
			{
				[videoImageRep drawInRect:[self bounds]];
			}
			
			return;
		}
		else if(videoImageRep != nil)
		{
			[videoImageRep release];
			videoImageRep = nil;
		}
	}
	
	// activating this context
	[openGLContext makeCurrentContext];
	
	// if size changed (window resizing), adjust viewport
	NSSize newSize = [self bounds].size;
	if (!NSEqualSizes(newSize, displaySize) || switchedPinPMode)
	{
		[openGLContext update];
		glViewport(0, 0, (GLint)newSize.width, (GLint)newSize.height);
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		
		gluPerspective(30.0,(GLdouble)newSize.width/(GLdouble)newSize.height,0.1,100.0);
		
		Camera currentCamera = currentPinPMode->camera;
		
		gluLookAt(currentCamera.eye.x, currentCamera.eye.y, currentCamera.eye.z, currentCamera.sceneCenter.x, currentCamera.sceneCenter.y,
				  currentCamera.sceneCenter.z, currentCamera.upVector.x, currentCamera.upVector.y, currentCamera.upVector.z);
		
		glMatrixMode(GL_MODELVIEW);
		
		displaySize = newSize;
		
		switchedPinPMode = NO;
	}

	float videoHeight = displaySize.height;
	float videoWidth = displaySize.width;
	
	// ensure correct aspect ration when in full screen
	XMVideoSize remoteVideoSize = [[XMVideoManager sharedInstance] remoteVideoSize];
	
	float aspectRatio = 0;
	
	if(remoteVideoSize == XMVideoSize_SQCIF ||
	   remoteVideoSize == XMVideoSize_320_240)
	{
		aspectRatio = 4.0/3.0;
	}
	else
	{
		aspectRatio = 11.0/9.0;
	}
	
	if (videoHeight/videoWidth != aspectRatio)
	{
		videoWidth = aspectRatio * videoHeight;
	}
	
	CVOpenGLTextureRef openGLTextureLocal = localVideo;
	CVOpenGLTextureRef openGLTextureRemote = remoteVideo;
	
	glEnable(GL_DEPTH_TEST);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	float depth = 0.0;

	glPushMatrix();
	glLoadIdentity();
	
	// drawing the remote video if possible
	if (openGLTextureRemote != nil)
	{
		GLenum targetRemote = CVOpenGLTextureGetTarget(openGLTextureRemote);
		GLint name = CVOpenGLTextureGetName(openGLTextureRemote);
		GLfloat topLeft[2], topRight[2], bottomRight[2], bottomLeft[2];
		CVOpenGLTextureGetCleanTexCoords(openGLTextureRemote, bottomLeft, bottomRight, topRight, topLeft);
		
		glEnable(targetRemote);
		glBindTexture(targetRemote, name);
		
		Placement remoteVideoPlacement = currentPinPMode->remoteVideoPlacement;
		glPushMatrix();
		glTranslatef(remoteVideoPlacement.position.x, remoteVideoPlacement.position.y, remoteVideoPlacement.position.z);
		glScalef(remoteVideoPlacement.scaling.x, remoteVideoPlacement.scaling.y, remoteVideoPlacement.scaling.z);
		glRotatef(-remoteVideoPlacement.rotationAngle, remoteVideoPlacement.rotationAxis.x, remoteVideoPlacement.rotationAxis.y, remoteVideoPlacement.rotationAxis.z);
		
		#ifdef __ANTIALIASED_POLY__
			glEnable( GL_POLYGON_OFFSET_FILL );
			glPolygonOffset( 1.0, 1.0 );
		#endif
		
		glScaled(videoWidth/videoHeight, 1.0, 1.0);
		
		[self _drawPolygon:depth bottomLeft:bottomLeft bottomRight:bottomRight topRight:topRight topLeft:topLeft mirrored:NO];
		
		#ifdef __ANTIALIASED_POLY__
			glDisable( GL_POLYGON_OFFSET_FILL );
			glEnable( GL_BLEND );
				glEnable( GL_LINE_SMOOTH );
					glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
					glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
					[self _drawPolygon:depth bottomLeft:bottomLeft bottomRight:bottomRight topRight:topRight topLeft:topLeft mirrored:NO];
					glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
				glDisable( GL_LINE_SMOOTH );
			glDisable( GL_BLEND );
		#endif
				
		glPopMatrix();
		if (currentPinPMode->remoteVideoPlacement.isReflected)
		{
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
			[self _drawPolygon:depth bottomLeft:bottomLeft bottomRight:bottomRight topRight:topRight topLeft:topLeft mirrored:NO];
				
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
						[self _drawPolygon:0.0 bottomLeft:bottomLeft bottomRight:bottomRight topRight:topRight topLeft:topLeft mirrored:NO];
						glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
					glDisable( GL_LINE_SMOOTH );
				glDisable( GL_BLEND );
#endif
			glPopAttrib();
			glPopMatrix();
			
		}
		
		glDisable(targetRemote);
	}
	
	if (openGLTextureLocal != nil)
	{
		GLenum targetLocal = CVOpenGLTextureGetTarget(openGLTextureLocal);
		GLint name = CVOpenGLTextureGetName(openGLTextureLocal);
		GLfloat topLeft[2], topRight[2], bottomRight[2], bottomLeft[2];
		CVOpenGLTextureGetCleanTexCoords(openGLTextureLocal, bottomLeft, bottomRight, topRight, topLeft);

		// drawing the local texture
		glEnable(targetLocal);
		glBindTexture(targetLocal, name);
		
		Placement localVideoPlacement = (*currentPinPMode).localVideoPlacement;
		glPushMatrix();
		glTranslatef(localVideoPlacement.position.x, localVideoPlacement.position.y, localVideoPlacement.position.z);
		glScalef(localVideoPlacement.scaling.x, localVideoPlacement.scaling.y, localVideoPlacement.scaling.z);
		glRotatef(-localVideoPlacement.rotationAngle, localVideoPlacement.rotationAxis.x, localVideoPlacement.rotationAxis.y, localVideoPlacement.rotationAxis.z);
		
		#ifdef __ANTIALIASED_POLY__
		if (currentPinPMode != &classicPinP){
			glEnable( GL_POLYGON_OFFSET_FILL );
			glPolygonOffset( 1.0, 1.0 );
		}
		#endif
		
		glScaled(videoWidth/videoHeight, 1.0, 1.0); 
		[self _drawPolygon:depth bottomLeft:bottomLeft bottomRight:bottomRight topRight:topRight topLeft:topLeft mirrored:isLocalVideoMirrored];
		
		#ifdef __ANTIALIASED_POLY__
		if (currentPinPMode != &classicPinP){
			glDisable( GL_POLYGON_OFFSET_FILL );
			glEnable( GL_BLEND );
			glEnable( GL_LINE_SMOOTH );
			glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
			glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
			[self _drawPolygon:depth bottomLeft:bottomLeft bottomRight:bottomRight topRight:topRight topLeft:topLeft mirrored:isLocalVideoMirrored];
			glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
			glDisable( GL_LINE_SMOOTH );
			glDisable( GL_BLEND );
		}
		#endif
		
		if (currentPinPMode == &classicPinP) //draw the border around local video area
		{
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


		if (currentPinPMode->localVideoPlacement.isReflected)
		{
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
			[self _drawPolygon:depth bottomLeft:bottomLeft bottomRight:bottomRight topRight:topRight topLeft:topLeft mirrored:isLocalVideoMirrored];

				
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
					[self _drawPolygon:0.0 bottomLeft:bottomLeft bottomRight:bottomRight topRight:topRight topLeft:topLeft mirrored:isLocalVideoMirrored];

					glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
					glDisable( GL_LINE_SMOOTH );
					glDisable( GL_BLEND );
				#endif
			glPopAttrib();
			glPopMatrix();
		}
		
		glDisable(targetLocal);
	}
		
	
	glColor3f(1.0f, 1.0f, 1.0f);
	glPopMatrix();
	
	// Flush the buffer to let the changes propagate to the screen
	glFlush();
}

/*
- (void)_windowWillMiniaturize:(NSNotification *)notif
{
	[osdControllerWindow closeWithEffect:NoEffect];
	isOSDDisplayed = NO;
	isMiniaturized = YES;
	[self _stopTimer];
	[self display];
}*/

/*- (void)_windowWillClose:(NSNotification *)notif{
	[osdControllerWindow closeWithEffect:NoEffect];
	[self _stopTimer];
}*/

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
	switchedPinPMode = YES;
}

- (void)animationDidStop:(NSAnimation *)animation // executes if the animation is aborted somehow
{
	currentPinPMode = targetPinPMode;
	switchedPinPMode = YES;
}

#pragma mark -
#pragma mark Polygon Drawing

- (void)_drawPolygon:(GLfloat)depth 
		  bottomLeft:(GLfloat*)bottomLeft 
		 bottomRight:(GLfloat*)bottomRight 
			topRight:(GLfloat*)topRight 
			 topLeft:(GLfloat*)topLeft
			mirrored:(BOOL)mirrored
{
	glBegin(GL_QUADS);
		if(mirrored == NO)
		{
			glTexCoord2fv(bottomLeft); glVertex3f(-1, -1, depth);
			glTexCoord2fv(topLeft); glVertex3f(-1, 1, depth);
			glTexCoord2fv(topRight); glVertex3f(1, 1, depth);
			glTexCoord2fv(bottomRight); glVertex3f(1, -1, depth);
		}
		else
		{
			glTexCoord2fv(bottomLeft); glVertex3f(1, -1, depth);
			glTexCoord2fv(topLeft); glVertex3f(1, 1, depth);
			glTexCoord2fv(topRight); glVertex3f(-1, 1, depth);
			glTexCoord2fv(bottomRight); glVertex3f(-1, -1, depth);
		}
	glEnd();
}

#pragma mark -
#pragma mark Event Handling

- (void)keyDown:(NSEvent *) event
{
    NSString *characters;
    characters = [event characters];
	
    unichar character;
    character = [characters characterAtIndex: 0];
	
	if (character == 27 && isFullScreen)
	{
		// user pressed escape key
		[(XMApplicationController *)[NSApp delegate] exitFullScreen];
	}
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	if (displayStatus == XM_DISPLAY_VIDEO && currentPinPMode == &classicPinP)
	{
		NSPoint transformedPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		transformedPoint = [self convertPoint:transformedPoint toView:self];
				
		Vector3 pinpPos = currentPinPMode->localVideoPlacement.position;
		
		//conversion to view coordinates
		float videoWidth = (currentPinPMode->localVideoPlacement.scaling.x * [self bounds].size.width);
		float videoHeight = (currentPinPMode->localVideoPlacement.scaling.y * [self bounds].size.height);
		float videoCenterX = (pinpPos.x + 1.0)/2.0 * [self bounds].size.width;
		float videoCenterY = (pinpPos.y + 1.0)/2.0 * [self bounds].size.height;
		
		NSRect pinpVideoRect = NSMakeRect(videoCenterX - videoWidth/2.0, videoCenterY - videoHeight/2.0, videoWidth, videoHeight);		
		
		if (NSPointInRect(transformedPoint, pinpVideoRect))
		{
			//back to ogl coordinates
		  float posX = 2.0 * ((transformedPoint.x - downPoint.x) / [self bounds].size.width) - 1.0;
		  float posY = 2.0 * ((transformedPoint.y - downPoint.y) / [self bounds].size.height) - 1.0 ;
		  		  
		  currentPinPMode->localVideoPlacement.position.x = posX;
		  currentPinPMode->localVideoPlacement.position.y = posY;
		}
	}
}
	
- (void)mouseEntered:(NSEvent *)theEvent
{
	if(osdDisplayMode == XMOSDDisplayMode_AutomaticallyHiding)
	{
		[self _displayOSD:osdOpeningEffect];
	}
	else if(osdDisplayMode == XMOSDDisplayMode_AlwaysVisible)
	{
		[self _displayOSD:XMOpeningEffect_NoEffect];
	}
}

- (void)mouseExited:(NSEvent *)theEvent
{
	if(osdDisplayMode != XMOSDDisplayMode_AutomaticallyHiding)
	{
		return;
	}
	if(osd != nil)
	{
		NSRect viewRect = [osd osdRect];
		
		// avoid osd blinking by not hiding OSD when mouse
		// over OSD
		viewRect.size.height += 2;
		viewRect.size.width += 2;
		viewRect.origin.x -= 1;
		
		NSPoint mouseLocation = [theEvent locationInWindow];
		mouseLocation = [self convertPoint:mouseLocation fromView:nil];
		
		if(!NSPointInRect(mouseLocation, viewRect))
		{
			[self _hideOSD:osdClosingEffect];
		}
	}
}

#pragma mark -
#pragma mark Notifications

- (void)_frameDidChange:(NSNotification *)notif
{
	if(osd != nil)
	{
		NSRect viewRect = [self bounds];
		
		NSPoint viewOrigin = viewRect.origin;
		viewOrigin = [self convertPoint:viewOrigin toView:nil];
		viewOrigin = [[self window] convertBaseToScreen:viewOrigin];
		viewRect.origin = viewOrigin;
	
		[osdControllerWindow setFrame:viewRect display:YES];
	}
	[self _resetOSDTrackingRect];
}

#pragma mark -
#pragma mark Private Methods

- (void)_displayOSD:(XMOpeningEffect)openingEffect
{
	XMOSDSize osdSize = XMOSDSize_Small;
	if(isFullScreen)
	{
		osdSize = XMOSDSize_Large;
	}
	
	if(osd == nil)
	{		
		NSRect viewRect = [self bounds];
		NSPoint viewOrigin = viewRect.origin;
		viewOrigin = [self convertPoint:viewOrigin toView:nil];
		viewOrigin = [[self window] convertBaseToScreen:viewOrigin];
		
		viewRect.origin = viewOrigin;
		
		// Choose the right OSD type
		if(displayStatus == XM_DISPLAY_VIDEO)
		{
			osd = [[XMInCallOSD alloc] initWithFrame:[self frame] videoView:self andSize:osdSize];
			[(XMInCallOSD *)osd setIsFullScreen:isFullScreen];
		}
		else
		{
			osd = [[XMAudioOnlyOSD alloc] initWithFrame:[self frame] videoView:self andSize:osdSize];
		}
		
		osdControllerWindow = [[XMOnScreenControllerWindow alloc] initWithControllerView:osd contentRect:viewRect];
	}
	else
	{
		[osd setOSDSize:osdSize];
	}
	
	[osdControllerWindow openWithEffect:openingEffect parentWindow:[self window]];
	
	doesShowOSD = YES;
}

- (void)_hideOSD:(XMClosingEffect)closingEffect
{
	[osdControllerWindow closeWithEffect:closingEffect];
	
	doesShowOSD = NO;
}

- (void)_resetOSDTrackingRect
{
	if(osdTrackingRect != 0)
	{
		[self removeTrackingRect:osdTrackingRect];
		osdTrackingRect = 0;
	}
	
	if(osdDisplayMode == XMOSDDisplayMode_NoOSD)
	{
		return;
	}
	
	NSRect bounds = [self bounds];
	
	XMOSDSize size;
	float osdHeightSpacing = 0;
	
	if(isFullScreen)
	{
		osdHeightSpacing = 50.0;
		size = XMOSDSize_Large;
	}
	else
	{
		osdHeightSpacing = 20.0;
		size = XMOSDSize_Small;
	}
	
	float height = [XMOnScreenControllerView osdHeightForSize:size];
	
	bounds.size.height = height + osdHeightSpacing;
	
	NSTrackingRectTag theTrackingRect = [self addTrackingRect:bounds owner:self userData:"osdData" assumeInside:NO];
	
	if(theTrackingRect != 0)
	{
		osdTrackingRect = theTrackingRect;
	}
}

@end
