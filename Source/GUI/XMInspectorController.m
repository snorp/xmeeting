/*
 * $Id: XMInspectorController.m,v 1.2 2006/02/28 09:14:48 zmit Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Ivan Guajana. All rights reserved.
 */


#import "XMInspectorController.h"
#import "XMMainWindowAdditionModule.h"

@interface XMInspectorController (PrivateMethods)
- (void)_showModule:(id)module;
- (void)_setupInterface;
@end

@implementation XMInspectorController

#pragma mark Class Methods

+ (XMInspectorController *)instanceWithModules:(NSArray*)m andName:(NSString*)name{	
	XMInspectorController *instance= nil;
	if (instances == nil) 
		instances = [[NSMutableDictionary alloc] initWithCapacity:2];
	else
		instance = [instances objectForKey:name];
	
	if(instance == nil)
	{
		if (m){
			instance = [[XMInspectorController alloc] initWithModules:m andName:name];
			[instances setObject:instance forKey:name];
			[instance release]; //retained by dictionary
		}
	}
	
	return instance;
}

+ (XMInspectorController *)instanceWithName:(NSString*)name{
	return [instances objectForKey:name];
}

+ (void)closeAllInspectors{
	[[instances allValues] makeObjectsPerformSelector:@selector(close)];
}

#pragma mark -
#pragma mark Initialization
	//Init
- (id)initWithModules:(id)mod andName:(NSString*)n{	
	if (!(self = [super init])) return nil;

	[self setModules:mod];
	[self setName:n];
	
	return self;
}

- (void)awakeFromNib{
	[self _setupInterface];
	[panel orderFront:self];
	//[panel setLevel:NSScreenSaverWindowLevel+2]; //OSD is NSScreenSaverWindowLevel+1. This ensures it doesn't get over
}

- (void)dealloc{
	[super dealloc];
	[instances release];
}

#pragma mark -
#pragma mark Get&Set
- (void)setModules:(NSArray*)m{
	id tmp = modules;
	modules = [m retain];
	if (tmp) [tmp release];
	[self _setupInterface];
}

- (NSString*)name{
	return name;
}

- (void)setName:(NSString*)newName{
	id tmp = name;
	name = [newName retain];
	[tmp release];
}

#pragma mark -
#pragma mark Actions
- (IBAction)changePage:(id)sender{
	id newModule = [modules objectAtIndex:[sender indexOfSelectedItem]];
	[self _showModule:newModule];
}
#pragma mark -
#pragma mark Public Methods
- (void)close{
	[panel orderOut:self];
}

- (void)show{
	[panel orderFront:self];
}

- (void)currentModuleSizeChanged:(id)sender{
	[self _showModule:currentModule];
}

#pragma mark -
#pragma mark Private Methods

- (void)_setupInterface{
	[panel setTitle:name];
	
	int moduleCount = [modules count];
	[pageController setSegmentCount:moduleCount];
	
	int i;
	for (i = 0; i < [modules count]; i++){
		id curModule = [modules objectAtIndex:i];
		[pageController setLabel:[curModule name] forSegment:i];
		
		if ([curModule respondsToSelector:@selector(image)]){
			[pageController setImage:[curModule image] forSegment:i];
		}
		
		[pageController setWidth:0 forSegment:i]; //autosize
	}
	[pageController setSelectedSegment:0];
	[self _showModule:[modules objectAtIndex:0]];
	
}

- (void)_showModule:(id)module{
	NSRect panelFrame = [panel frame];
	NSSize boxSize = [contentBox frame].size;
	NSSize moduleSize = [module contentViewSize];
	
	float deltaX = moduleSize.width - boxSize.width;
	float deltaY = moduleSize.height - boxSize.height;
	
	panelFrame.size.width += deltaX;
	panelFrame.size.height += deltaY;
	panelFrame.origin.y -= deltaY;
	
	[contentBox setContentView:nil];
	
	[panel setFrame:panelFrame display:YES animate:YES];

	[currentModule becomeInactiveModule];
	[module becomeActiveModule];
	[contentBox setContentView:[module contentView]];
	
	currentModule = module;
	
	if ([module respondsToSelector:@selector(isResizableWhenInSeparateWindow)] && [module isResizableWhenInSeparateWindow]){
		[panel setShowsResizeIndicator:YES];
	} 
	else
	{
		[panel setShowsResizeIndicator:NO];	
	}
}

@end
