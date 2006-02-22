/*
 * $Id: XMInspectorController.h,v 1.1 2006/02/22 16:12:33 zmit Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Ivan Guajana. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

//Instances
static NSMutableDictionary* instances;

@interface XMInspectorController : NSObject {
	
	NSArray *modules;
	NSString* name;
	
	//Outlets
	IBOutlet NSBox *contentBox;
	IBOutlet NSSegmentedControl *pageController;
	IBOutlet NSPanel *panel;
			
	id currentModule;
		
}

//Class methods
+ (XMInspectorController *)instanceWithModules:(NSArray*)m andName:(NSString*)name;
+ (XMInspectorController *)instanceWithName:(NSString*)name;
+ (void)closeAllInspectors;

//Actions
- (IBAction)changePage:(id)sender;

//Get&Set
- (void)setModules:(NSArray*)m;
- (NSString*)name;
- (void)setName:(NSString*)newName;

//Init
- (id)initWithModules:(id)mod andName:(NSString*)name;

//Other
- (void)currentModuleSizeChanged:(id)sender;
- (void)show;
- (void)close;
@end
