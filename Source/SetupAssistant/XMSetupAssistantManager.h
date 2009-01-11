/*
 * $Id: XMSetupAssistantManager.h,v 1.13 2009/01/11 17:20:41 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_SETUP_ASSISTANT_MANAGER_H__
#define __XM_SETUP_ASSISTANT_MANAGER_H__

#import <Cocoa/Cocoa.h>
#import "XMeeting.h"

@class XMLocation;
@class XMH323Account;
@class XMSIPAccount;

/**
 * List of attributes
 **/
extern NSString *XMAttribute_FirstLaunch;
extern NSString *XMAttribute_PreferencesEdit;
extern NSString *XMAttribute_LocationImport;
extern NSString *XMAttribute_LastLocation;
extern NSString *XMAttribute_NewLocation;
extern NSString *XMAttribute_EditLocation;
extern NSString *XMAttribute_GatekeeperLastLocation;
extern NSString *XMAttribute_UseGatekeeper;
extern NSString *XMAttribute_SIPRegistrationLastLocation;
extern NSString *XMAttribute_UseSIPRegistration;

@protocol XMSetupAssistantData <NSObject>

- (NSArray *)locations;

- (BOOL)hasAttribute:(NSString *)attribute;
- (NSObject *)getAttribute:(NSString *)attribute;
- (void)setAttribute:(NSString *)attribute;
- (void)setAttribute:(NSString *)attribute value:(NSObject *)value;
- (void)clearAttribute:(NSString *)attribute;

- (XMLocation *)currentLocation;
- (void)setCurrentLocation:(XMLocation *)location;
- (XMLocation *)createLocation;

- (NSString *)username;
- (void)setUsername:(NSString *)username;

- (void)clearH323AccountInfo;
- (void)saveH323AccountInfo;
- (NSString *)gkHost;
- (void)setGKHost:(NSString *)host;
- (NSString *)gkUserAlias1;
- (void)setGKUserAlias1:(NSString *)userAlias;
- (NSString *)gkUserAlias2;
- (void)setGKUserAlias2:(NSString *)userAlias;
- (NSString *)gkPassword;
- (void)setGKPassword:(NSString *)password;

- (void)clearSIPAccountInfo;
- (void)saveSIPAccountInfo;
- (NSString *)sipRegDomain;
- (void)setSIPRegDomain:(NSString *)domain;
- (NSString *)sipRegUsername;
- (void)setSIPRegUsername:(NSString *)username;
- (NSString *)sipRegAuthorizationUsername;
- (void)setSIPRegAuthorizationUsername:(NSString *)authorizationUsername;
- (NSString *)sipRegPassword;
- (void)setSIPRegPassword:(NSString *)password;

@end

@protocol XMSetupAssistantModule <NSObject>

- (NSArray *)editKeys;
- (BOOL)isActiveForData:(id<XMSetupAssistantData>)data;

- (NSString *)titleForData:(id<XMSetupAssistantData>)data;
- (BOOL)showCornerImage;
- (NSView *)contentView;

- (BOOL)canContinue;

- (void)loadData:(id<XMSetupAssistantData>)data;
- (void)saveData:(id<XMSetupAssistantData>)data;
- (void)editData:(NSArray *)editKeys;

@end

@protocol XMSetupAssistantController <NSObject>

- (id<XMSetupAssistantModule>)nextModule;
- (id<XMSetupAssistantModule>)previousModule;
- (BOOL)hasNextModule;
- (BOOL)hasPreviousModule;

- (void)cancel;

@end

@interface XMSetupAssistantManager : NSWindowController <XMSetupAssistantData> {
	
@private
  
  NSObject *delegate;
  SEL didEndSelector;
  
  NSArray *locations;
  NSArray *h323Accounts;
  NSArray *sipAccounts;
  XMLocation *currentLocation;
  NSString *username;
  NSString *gkHost;
  NSString *gkUserAlias1;
  NSString *gkUserAlias2;
  NSString *gkPassword;
  NSString *sipRegDomain;
  NSString *sipRegUsername;
  NSString *sipRegAuthorizationUsername;
  NSString *sipRegPassword;
  
  id<XMSetupAssistantController> controller;
  id<XMSetupAssistantModule> currentModule;
  
  NSArray *editKeys;
  NSMutableDictionary *attributes;
  
  IBOutlet NSView *contentView;
  
  IBOutlet NSButton *continueButton;
  IBOutlet NSButton *goBackButton;
  IBOutlet NSButton *cancelButton;
  IBOutlet NSButton *detailedViewButton;
  
  IBOutlet NSTextField *titleField;
  IBOutlet NSImageView *cornerImage;
  IBOutlet NSBox *contentBox;
  
@public
  IBOutlet id<XMSetupAssistantModule> generalSettingsModule;
  IBOutlet id<XMSetupAssistantModule> locationModule;
  IBOutlet id<XMSetupAssistantModule> newLocationModule;
  IBOutlet id<XMSetupAssistantModule> networkModule;
  IBOutlet id<XMSetupAssistantModule> protocolModule;
  IBOutlet id<XMSetupAssistantModule> h323Module;
  IBOutlet id<XMSetupAssistantModule> gatekeeperModule;
  IBOutlet id<XMSetupAssistantModule> sipModule;
  IBOutlet id<XMSetupAssistantModule> registrationModule;
  IBOutlet id<XMSetupAssistantModule> videoModule;
  
  IBOutlet id<XMSetupAssistantModule> editIntroductionModule;
  IBOutlet id<XMSetupAssistantModule> editDoneModule;
  
  IBOutlet id<XMSetupAssistantModule> firstLaunchIntroductionModule;
  IBOutlet id<XMSetupAssistantModule> firstLaunchDoneModule;
}

+ (XMSetupAssistantManager *)sharedInstance;

- (void)runEditAssistantInWindow:(NSWindow *)window;
- (void)abortEditAssistant;
- (void)finishEditAssistant;

/**
 * Runs the assistant in the first application launch mode. When the
 * assistant has finished, didEndSelector is invoked. This selector
 * should have the form 
 * -assistantDidEnd
 **/
- (void)runFirstApplicationLaunchAssistantWithDelegate:(NSObject *)delegate
										didEndSelector:(SEL)didEndSelector;

/**
 * Runs the assistant to import locations. When the assistant
 * has finished, didEndSelector is invoked. This selector should
 * have the form 
 * -assistantDidEndWithLocations:(NSArray *)locations
 *					h323Accounts:(NSArray *)h323Accounts
 *					 sipAccounts:(NSArray *)sipAccounts
 *
 * locations contains the imported locations or zero elements in
 * case the user canceled.
 * h323Accounts contains any H.323 accounts created by this assistant
 * sipAccounts contains any SIP accounts created by this assistant
 **/
- (void)runImportLocationsAssistantModalForWindow:(NSWindow *)window
									modalDelegate:(NSObject *)modalDelegate
								   didEndSelector:(SEL)didEndSelector;
- (void)abortFirstLaunchAssistant;
- (void)finishFirstLaunchAssistant;

- (NSSize)contentViewSize;

- (id<XMSetupAssistantController>)controller;
- (id<XMSetupAssistantModule>)currentModule;

- (void)setEditKeys:(NSArray *)editKeys;
- (void)addLocation:(XMLocation *)location;

- (void)updateContinueStatus;

// action methods
- (IBAction)cancelAssistant:(id)sender;
- (IBAction)continueAssistant:(id)sender;
- (IBAction)goBackAssistant:(id)sender;
- (IBAction)switchToDetailedView:(id)sender;

@end

@interface XMSAEditController : NSObject <XMSetupAssistantController> {
  BOOL firstLocation;
  unsigned state;
  unsigned moduleIndex;
  id<XMSetupAssistantModule> introductionModule;
  id<XMSetupAssistantModule> generalModule;
  NSArray *modules;
}

- (id)initWithSetupAssistant:(XMSetupAssistantManager *)setupAssistant;

- (void)continueAssistant;

@end

@interface XMSAFirstLaunchController : NSObject <XMSetupAssistantController> {
  unsigned moduleIndex;
  NSArray *modules;
}

- (id)initWithSetupAssistant:(XMSetupAssistantManager *)setupAssistant;

@end

#endif // __XM_SETUP_ASSISTANT_MANAGER_H__
