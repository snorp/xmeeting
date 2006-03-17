/*
 * $Id: XMInspectorModule.m,v 1.1 2006/03/17 13:20:52 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich, Ivan Guajana. All rights reserved.
 */

#import "XMInspectorModule.h"

#import "XMInspectorController.h"

@implementation XMInspectorModule

#pragma mark Init & Deallocation Methods

- (id)init
{
	isEnabled = YES;
	
	return self;
}

#pragma mark -
#pragma mark XMInspectorModule base methods

- (void)setTag:(XMInspectorControllerTag)theTag
{
	tag = theTag;
}

- (BOOL)isEnabled
{
	return isEnabled;
}

- (void)setEnabled:(BOOL)flag
{
	if(isEnabled != flag)
	{
		isEnabled = flag;
		[[XMInspectorController inspectorWithTag:tag] moduleStatusChanged:self];
	}
}

- (void)resizeContentView
{
	[[XMInspectorController inspectorWithTag:tag] moduleSizeChanged:self];
}

#pragma mark -
#pragma mark Methods for subclasses to override

- (NSString *)name
{
	return nil;
}

- (NSImage *)image
{
	return nil;
}

- (NSView *)contentView
{
	return nil;
}

- (NSSize)contentViewSize
{
	return NSMakeSize(0, 0);
}

- (NSSize)contentViewMinSize
{
	return [self contentViewSize];
}

- (NSSize)contentViewMaxSize
{
	return [self contentViewSize];
}

- (void)becomeActiveModule
{
}

- (void)becomeInactiveModule
{
}

@end
