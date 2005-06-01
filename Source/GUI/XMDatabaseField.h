/*
 * $Id: XMDatabaseField.h,v 1.2 2005/06/01 11:00:37 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_DATABASE_FIELD_H__
#define __XM_DATABASE_FIELD_H__

#import <Cocoa/Cocoa.h>

/**
 * XMDatabaseFields extends the functionality of NSTextField
 * by allowing the data source to return an array of possible
 * completions to an entered string. The completions are displayed
 * in a pull-down menu, the same way as when the user entered
 * an uncomplete URL in Safari.
 **/
@interface XMDatabaseField : NSTextField {
	
	IBOutlet id dataSource;
	
	NSWindow *completionsWindow;
	NSScrollView *completionsScrollView;
	NSTableView *completionsTableView;
	NSArray *currentCompletions;
	BOOL completionsWindowIsShown;
	
	BOOL shouldFetchCompletions;
	
	NSString *uncompletedString;
	
	id representedObject;
	
	NSImage *defaultImage;
}

- (id)dataSource;
- (void)setDataSource:(id)dataSource;

- (NSImage *)defaultImage;
- (void)setDefaultImage:(NSImage *)image;

- (id)representedObject;
- (void)setRepresentedObject:(id)representedObject;

@end

/**
 * The protocol used to query the dataSource for information
 **/
@protocol XMDatabaseFieldDataSource

/**
 * Asks the data source to return an array of available completions
 * for the given uncompletedString. The data source may specify
 * which item to select and display in thetext field by 
 * setting indexOfSelectedItem accordingly.
 * This method is required to implement.
 **/
- (NSArray *)databaseField:(XMDatabaseField *)databaseField 
		 completionsForString:(NSString *)uncompletedString
		  indexOfSelectedItem:(unsigned *)indexOfSelectedItem;

/**
 * Asks the data source to return a represented object for the given completedString
 * This allows the dataSource to return a more complex object than a single NSString instance.
 * This Method is required to implement
 **/
- (id)databaseField:(XMDatabaseField *)databaseField representedObjectForCompletedString:(NSString *)completedString;

/**
 * The data source is queried for a display name for the represented object.
 * This Method is required to implement
 **/
- (NSString *)databaseField:(XMDatabaseField *)databaseField displayStringForRepresentedObject:(id)representedObject;

/**
 * This method may return an image for the represented object, or nil if there is no appropriate
 * image. In this case, the default image is used if there is one specified
 **/
- (NSImage *)databaseField:(XMDatabaseField *)databaseField imageForRepresentedObject:(id)representedObject;

@end

#endif // __XM_DATABASE_FIELD_H__
