/*
 * $Id: XMDatabaseField.h,v 1.9 2007/08/17 11:36:43 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_DATABASE_FIELD_H__
#define __XM_DATABASE_FIELD_H__

#import <Cocoa/Cocoa.h>

@protocol XMDatabaseFieldDataSource;

/**
 * XMDatabaseFields extends the functionality of NSTextField
 * by allowing the data source to return an array of possible
 * completions to an entered string. The completions are displayed
 * in a pull-down menu, the same way as when the user entered
 * an uncomplete URL in Safari. In addition to that, an url-like
 * image can be displayed at the beginning of the text field to indicate
 * the kind of text entered. This is similar to Safari behaviour.
 * Last, but not least, there is an NSComboBox-like pull down menu
 * available if the user clicks on the button at the right side of the
 * control.
 **/
@interface XMDatabaseField : NSTextField {

@private
  IBOutlet id<XMDatabaseFieldDataSource> dataSource;
  
  NSWindow *pulldownWindow;
  NSScrollView *pulldownScrollView;
  NSTableView *pulldownTableView;
  NSArray *tableData;
  BOOL windowIsShown;
  BOOL isOverDisclosure;
  unsigned pulldownMode;
  
  BOOL shouldFetchCompletions;
  
  NSString *uncompletedString;
  
  id representedObject;
  
  NSImage *defaultImage;
  
  NSTrackingRectTag disclosureTrackingRect;
}

/**
 * Gets / Sets the data source for this view
 **/
- (id)dataSource;
- (void)setDataSource:(id)dataSource;

/**
 * Gets / Sets the default image for this view
 **/
- (NSImage *)defaultImage;
- (void)setDefaultImage:(NSImage *)image;

/**
 * Gets / Sets the current represented object in
 * this view
 **/
- (id)representedObject;
- (void)setRepresentedObject:(id)representedObject;

/**
 * Causes the editing operation to end. The pull down menu
 * will disappear if open, the edited text will be replaced
 * by a text from the data source and the image will be adjusted
 * if needed
 **/
- (void)endEditing;

@end

/**
 * The protocol used to query the dataSource for information
 **/
@protocol XMDatabaseFieldDataSource

/**
 * Asks the data source to return an array of available completions
 * for the given uncompletedString. The data source may specify
 * which item to select and display in the text field by 
 * setting indexOfSelectedItem accordingly.
 * This method is required to implement.
 **/
- (NSArray *)databaseField:(XMDatabaseField *)databaseField 
	  completionsForString:(NSString *)uncompletedString
	   indexOfSelectedItem:(unsigned *)indexOfSelectedItem;

/**
 * Asks the data source to return a represented object for the given completedString
 * This allows the dataSource to return a more complex object than a single NSString instance.
 * This method is required to implement
 **/
- (id)databaseField:(XMDatabaseField *)databaseField representedObjectForCompletedString:(NSString *)completedString;

/**
 * The data source is queried for a display name for the represented object.
 * This method is required to implement
 **/
- (NSString *)databaseField:(XMDatabaseField *)databaseField displayStringForRepresentedObject:(id)representedObject;

/** 
 * This method may return an image for the represented object, or nil if there is no appropriate
 * image. In this case, the default image is used if there is one specified.
 * This method is required to implement.
 **/
- (NSImage *)databaseField:(XMDatabaseField *)databaseField imageForRepresentedObject:(id)representedObject;

/**
 * Asks the data source to return an array of NSString instances. These instances will be displayed
 * in a pull down menu when the user clicks on the image in the view. If the array contains no elements,
 * no pull down menu appears.
 * By setting selectedIndex to a valid number, the source can determine which option is initially selected
 * This method is required to implement
 **/
- (NSArray *)imageOptionsForDatabaseField:(XMDatabaseField *)databaseField selectedIndex:(unsigned *)selectedIndex;

/**
 * Informs the data source that the user selected one of the text options.
 * This method is required to implement
 * Both imageOption and index are passed to allow efficient implementations
 **/
- (void)databaseField:(XMDatabaseField *)databaseField userSelectedImageOption:(NSString *)imageOption index:(unsigned)index;

/**
 * Asks the data source to return an array of objects that the user can choose from. This array
 * will be shown in a pull down menu if the user clicks on the disclosure at the right side of the view. 
 * If the user chooses an item in the pull down menu, the corresponding object will be taken as the
 * represented object and the view is displayed accordingly.
 * This method is required to implement
 **/
- (NSArray *)pulldownObjectsForDatabaseField:(XMDatabaseField *)databaseField;

@end

#endif // __XM_DATABASE_FIELD_H__
