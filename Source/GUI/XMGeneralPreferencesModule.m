/*
 * $Id: XMGeneralPreferencesModule.m,v 1.1 2005/04/28 20:26:27 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMGeneralPreferencesModule.h"
#import "XMPreferencesWindowController.h"

NSString *XMKey_GeneralPreferencesModuleIdentifier = @"XMeeting_GeneralPreferencesModule";

@implementation XMGeneralPreferencesModule

- (id)init
{
	prefWindowController = [[XMPreferencesWindowController sharedInstance] retain];
	
	return self;
}

- (void)awakeFromNib
{
	[prefWindowController addPreferencesModule:self];
}

- (void)dealloc
{
	[prefWindowController release];

	[super dealloc];
}

- (unsigned)position
{
	return 0;
}

- (NSString *)identifier
{
	return XMKey_GeneralPreferencesModuleIdentifier;
}

- (NSString *)toolbarLabel
{
	return NSLocalizedString(@"General", @"GeneralPreferencesModuleLabel");
}

- (NSImage *)toolbarImage
{
	return nil;
}

- (NSString *)toolTipText
{
	return NSLocalizedString(@"General Purpose Preferences", @"GeneralPreferencesModuleToolTip");
}

- (NSView *)contentView
{
	return contentView;
}

- (float)contentViewHeight
{
	return (float)300;
}

- (void)loadPreferences
{
}

- (void)revertPreferences
{
}

- (void)savePreferences
{
}

@end
