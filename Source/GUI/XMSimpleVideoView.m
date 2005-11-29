/*
 * $Id: XMSimpleVideoView.m,v 1.1 2005/11/29 18:56:29 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMSimpleVideoView.h"

#import <OpenGL/OpenGL.h>
#import <QuartzCore/QuartzCore.h>

#import "XMWindow.h"

#define XM_DISPLAY_NO_VIDEO 0
#define XM_DISPLAY_LOCAL_VIDEO 1
#define XM_DISPLAY_REMOTE_VIDEO 2

@interface XMSimpleVideoView (PrivateMethods)

- (void)_init;
- (void)_windowWillMiniaturize:(NSNotification *)notif;
- (void)_windowDidDeminiaturize:(NSNotification *)notif;
- (void)_didStartSelectedInputDeviceChange:(NSNotification *)notif;
- (void)_didChangeSelectedInputDevice:(NSNotification *)notif;

@end

@implementation XMSimpleVideoView

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
	openGLContext = nil;
	displayState = XM_DISPLAY_NO_VIDEO;
	previousSize = NSMakeSize(0, 0);
	
	ciImageRep = nil;
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
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[openGLContext release];
	
	[super dealloc];
}

#pragma mark Overriding NSView methods

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
								   name:XMNotification_WindowWillMinimize object:[self window]];
		[notificationCenter addObserver:self selector:@selector(_windowDidDeminiaturize:)
								   name:NSWindowDidDeminiaturizeNotification object:[self window]];
		[notificationCenter addObserver:self selector:@selector(_didStartSelectedInputDeviceChange:)
								   name:XMNotification_VideoManagerDidStartSelectedInputDeviceChange object:nil];
		[notificationCenter addObserver:self selector:@selector(_didChangeSelectedInputDevice:)
								   name:XMNotification_VideoManagerDidChangeSelectedInputDevice object:nil];
		
		if(displayState == XM_DISPLAY_LOCAL_VIDEO)
		{
			isBusy = YES;
			[busyIndicator startAnimation:self];
			[busyIndicator setHidden:NO];
		}
		
		// finally, register at the manager so that we get called every time a frame changed
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

#pragma mark public Methods

- (void)startDisplayingLocalVideo
{
	displayState = XM_DISPLAY_LOCAL_VIDEO;
}

- (void)startDisplayingRemoteVideo
{
	displayState = XM_DISPLAY_REMOTE_VIDEO;
}

- (void)stopDisplayingVideo
{
	displayState = XM_DISPLAY_NO_VIDEO;
}

- (void)renderLocalVideo:(CVOpenGLTextureRef)localVideo didChange:(BOOL)localVideoDidChange 
			 remoteVideo:(CVOpenGLTextureRef)remoteVideo didChange:(BOOL)remoteVideoDidChange
				isForced:(BOOL)isForced
{	
	CVOpenGLTextureRef openGLTexture = NULL;
	
	if(displayState == XM_DISPLAY_NO_VIDEO)
	{
		return;
	}
	
	if(isForced == YES)
	{
		if(isMiniaturized == YES)
		{
			if(ciImageRep == nil)
			{
				if(displayState == XM_DISPLAY_LOCAL_VIDEO)
				{
					openGLTexture = localVideo;
				}
				else if(displayState == XM_DISPLAY_REMOTE_VIDEO)
				{
					openGLTexture = remoteVideo;
				}
				
				if(openGLTexture == nil)
				{
					return;
				}
				
				CIImage *image = [[CIImage alloc] initWithCVImageBuffer:openGLTexture];
				ciImageRep = [[NSCIImageRep alloc] initWithCIImage:image];
				[image release];
			}
			
			[ciImageRep drawInRect:[self bounds]];
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
		
		if(ciImageRep != nil)
		{
			[ciImageRep release];
			ciImageRep = nil;
		}
	}
	else if(isMiniaturized == YES || isBusy == YES)
	{
		return;
	}
		
	// do not draw if there is nothing to draw...
	if(displayState == XM_DISPLAY_LOCAL_VIDEO)
	{
		if(localVideoDidChange == NO || localVideo == nil)
		{
			return;
		}
		else
		{
			openGLTexture = localVideo;
		}
	}
	else
	{
		if(remoteVideoDidChange == NO || remoteVideo == nil)
		{
			return;
		}
		else
		{
			openGLTexture = remoteVideo;
		}
	}
	
	if([openGLContext view] == nil)
	{
		[openGLContext setView:self];
	}
	
	// activating this context
	[openGLContext makeCurrentContext];
	
	// adjusting for any size changes
	NSSize newSize = [self bounds].size;
	if (!NSEqualSizes(newSize, previousSize))
	{
		[openGLContext update];
		glViewport(0, 0, (GLint)newSize.width, (GLint)newSize.height);
		
		previousSize = newSize;
	}
	
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	// getting info about the texture to draw
	GLenum target = CVOpenGLTextureGetTarget(openGLTexture);
	GLint name = CVOpenGLTextureGetName(openGLTexture);
	GLfloat topLeft[2], topRight[2], bottomRight[2], bottomLeft[2];
	CVOpenGLTextureGetCleanTexCoords(openGLTexture, bottomLeft, bottomRight, topRight, topLeft);
	
	// drawing the texture
	glEnable(target);
	glBindTexture(target, name);
	
	glBegin(GL_QUADS);
	glTexCoord2fv(bottomLeft); glVertex2f(-1, -1);
	glTexCoord2fv(topLeft); glVertex2f(-1, 1);
	glTexCoord2fv(topRight); glVertex2f(1, 1);
	glTexCoord2fv(bottomRight); glVertex2f(1, -1);
	glEnd();
	
	glDisable(target);
	
	// Flush the buffer to let the changes propagate to the screen
	glFlush();
}

#pragma mark Private Methods

- (void)_windowWillMiniaturize:(NSNotification *)notif
{
	isMiniaturized = YES;
	
	[self display];
}

- (void)_windowDidDeminiaturize:(NSNotification *)notif
{
	isMiniaturized = NO;
}

- (void)_didStartSelectedInputDeviceChange:(NSNotification *)notif
{
	if(displayState == XM_DISPLAY_LOCAL_VIDEO)
	{
		isBusy = YES;
		
		[busyIndicator startAnimation:self];
		[busyIndicator setHidden:NO];
		
		[self display];
	}
}

- (void)_didChangeSelectedInputDevice:(NSNotification *)notif
{
	if(displayState == XM_DISPLAY_LOCAL_VIDEO && isBusy == YES)
	{
		isBusy = NO;
		
		[busyIndicator setHidden:YES];
		[busyIndicator stopAnimation:self];
	}
}

@end
