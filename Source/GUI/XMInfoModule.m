/*
 * $Id: XMInfoModule.m,v 1.30 2008/12/27 08:06:47 hfriederich Exp $
 *
 * Copyright (c) 2006-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2008 Ivan Guajana, Hannes Friederich. All rights reserved.
 */

#import "XMInfoModule.h"

#import "XMeeting.h"
#import "XMPreferencesManager.h"
#import "XMH323Account.h"
#import "XMSIPAccount.h"
#import "XMLocation.h"
#import "XMApplicationFunctions.h"
#import "XMInspectorController.h"

#define XM_BOTTOM_SPACING 1
#define XM_BOX_X 2
#define XM_BOX_SPACING 13
#define XM_DISCLOSURE_OFFSET -2
#define XM_HIDDEN_OFFSET 4

#define XM_IP_ADDRESSES_TEXT_FIELD_HEIGHT 14
#define XM_ALIASES_TEXT_FIELD_HEIGHT 14
#define XM_REGISTRATION_INFO_HEIGHT 18

#define XM_SHOW_H323_DETAILS 1
#define XM_SHOW_SIP_DETAILS 2

NSString *XMKey_InfoModuleDetailStatus = @"XMeeting_InfoModuleDetailStatus";

@interface XMInfoModule (PrivateMethods)

- (void)_updateNetworkStatus:(NSNotification *)notif;
- (void)_updateProtocolStatus:(NSNotification *)notif;
- (void)_storeDetailStatus;
- (NSTextField *)_copyTextField:(NSTextField *)textField;
- (NSImageView *)_copyImageView:(NSImageView *)imageView;

@end

@implementation XMInfoModule

#pragma mark Init & Deallocation Methods

- (id)init
{
  self = [super init];
  
  terminalAliasViews = [[NSMutableArray alloc] initWithCapacity:3];
  registrationViews = [[NSMutableArray alloc] initWithCapacity:3];
  
  addressExtraHeight = 0;
  h323BoxHeight = 0;
  h323AliasesExtraHeight = 0;
  sipBoxHeight = 0;
  sipRegistrationsExtraHeight = 0;
  
  showH323Details = NO;
  showSIPDetails = NO;
  
  return self;
}

- (void)dealloc
{  
  [terminalAliasViews release];
  [registrationViews release];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [super dealloc];
}

- (void)awakeFromNib
{
  contentViewSize = [contentView frame].size;
  
  h323BoxHeight = [h323Box frame].size.height - XM_HIDDEN_OFFSET;
  sipBoxHeight = [sipBox frame].size.height - XM_HIDDEN_OFFSET;
  float networkBoxHeight = [networkBox frame].size.height;
  float boxWidth = [networkBox frame].size.width;
  
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  
  [notificationCenter addObserver:self selector:@selector(_updateNetworkStatus:) name:XMNotification_UtilsDidUpdateNetworkInformation object:nil];
  
  [notificationCenter addObserver:self selector:@selector(_updateProtocolStatus:) name:XMNotification_CallManagerDidEndSubsystemSetup object:nil];
  [notificationCenter addObserver:self selector:@selector(_updateProtocolStatus:) name:XMNotification_CallManagerDidChangeGatekeeperRegistrationStatus object:nil];
  
  unsigned detailStatus = [[NSUserDefaults standardUserDefaults] integerForKey:XMKey_InfoModuleDetailStatus];
  
  if (detailStatus & XM_SHOW_H323_DETAILS) {
    showH323Details = YES;
    [h323Disclosure setState:NSOnState];
  } else {
    showH323Details = NO;
    [h323Disclosure setState:NSOffState];
  }
  
  if (detailStatus & XM_SHOW_SIP_DETAILS) {
    showSIPDetails = YES;
    [sipDisclosure setState:NSOnState];
  } else {
    showSIPDetails = NO;
    [sipDisclosure setState:NSOffState];
  }
  
  [self _updateNetworkStatus:nil];
  [self _updateProtocolStatus:nil];
  
  // Manually adjusting the frame rects of the contained elements.
  // Otherwise, the resulting GUI does not behave and look as
  // expected, unfortunately
  NSSize size = [self contentViewSize];
  [contentView setFrameSize:size];
  
  NSRect frameRect = NSMakeRect(XM_BOX_X, XM_BOTTOM_SPACING, boxWidth, XM_HIDDEN_OFFSET);
  
  if (showSIPDetails == YES) {
    frameRect.size.height += sipBoxHeight + sipRegistrationsExtraHeight;
  } else {
    [sipBox setHidden:YES];
  }
  [sipBox setFrame:frameRect];
  
  frameRect.origin.y += frameRect.size.height+XM_DISCLOSURE_OFFSET;
  
  NSRect rect = [sipDisclosure frame];
  rect.origin.y = frameRect.origin.y;
  [sipDisclosure setFrame:rect];
  rect = [sipTitle frame];
  rect.origin.y = frameRect.origin.y;
  [sipTitle setFrame:rect];
  
  frameRect.origin.y -= XM_DISCLOSURE_OFFSET;
  frameRect.origin.y += XM_BOX_SPACING;
  frameRect.size.height = XM_HIDDEN_OFFSET;
  
  if (showH323Details == YES) {
    frameRect.size.height += h323BoxHeight + h323AliasesExtraHeight;
  } else {
    [h323Box setHidden:YES];
  }
  [h323Box setFrame:frameRect];
  
  frameRect.origin.y += frameRect.size.height+XM_DISCLOSURE_OFFSET;
  
  rect = [h323Disclosure frame];
  rect.origin.y = frameRect.origin.y;
  [h323Disclosure setFrame:rect];
  rect = [h323Title frame];
  rect.origin.y = frameRect.origin.y;
  [h323Title setFrame:rect];
  
  frameRect.origin.y -= XM_DISCLOSURE_OFFSET;
  frameRect.origin.y += XM_BOX_SPACING;
  frameRect.size.height = networkBoxHeight + addressExtraHeight;
  
  [networkBox setFrame:frameRect];
  
  [ipAddressesField setAutoresizingMask:NSViewHeightSizable];
  rect = [ipAddressesField frame];
  rect.size.height += addressExtraHeight;
  [ipAddressesField setFrame:rect];
}

#pragma mark -
#pragma mark Protocol Methods

- (NSString *)identifier
{
  return @"Info";
}

- (NSString *)name
{
  return NSLocalizedString(@"XM_INFO_MODULE_NAME", @"");
}

- (NSImage *)image
{
  return [NSImage imageNamed:@"Inspect_small"];
}

- (NSView *)contentView
{
  if (contentView == nil)
  {
    [NSBundle loadNibNamed:@"Info" owner:self];
  }
  
  return contentView;
}

- (NSSize)contentViewSize
{
  // if not already done, causing the nib file to load
  [self contentView];
  
  int heightDifference = addressExtraHeight;
  
  if (showH323Details == NO) {
    heightDifference -= h323BoxHeight;
  } else {
    heightDifference += h323AliasesExtraHeight;
  }
  if (showSIPDetails == NO) {
    heightDifference -= sipBoxHeight;
  } else {
    heightDifference += sipRegistrationsExtraHeight;
  }
  
  return NSMakeSize(contentViewSize.width, contentViewSize.height+heightDifference);
}

- (void)becomeActiveModule
{
}

- (void)becomeInactiveModule
{
}

#pragma mark -
#pragma mark Action Methods

- (IBAction)toggleShowH323Details:(id)sender
{
  showH323Details = !showH323Details;
  
  if (showH323Details == NO) {
    [h323Box setHidden:YES];
  }
  
  [networkBox setAutoresizingMask:NSViewMinYMargin];
  
  [h323Box setAutoresizingMask:NSViewHeightSizable];
  [h323Disclosure setAutoresizingMask:NSViewMinYMargin];
  [h323Title setAutoresizingMask:NSViewMinYMargin];
  
  [self resizeContentView];
  
  [networkBox setAutoresizingMask:NSViewHeightSizable];
  
  [h323Box setAutoresizingMask:NSViewMaxYMargin];
  [h323Disclosure setAutoresizingMask:NSViewMaxYMargin];
  [h323Title setAutoresizingMask:NSViewMaxYMargin];
  
  if (showH323Details == YES) {
    [h323Box setHidden:NO];
  }
  
  [self _storeDetailStatus];
}

- (IBAction)toggleShowSIPDetails:(id)sender
{
  showSIPDetails = !showSIPDetails;
  
  if (showSIPDetails == NO) {
    [sipBox setHidden:YES];
  }
  
  [networkBox setAutoresizingMask:NSViewMinYMargin];
  
  [h323Box setAutoresizingMask:NSViewMinYMargin];
  [h323Disclosure setAutoresizingMask:NSViewMinYMargin];
  [h323Title setAutoresizingMask:NSViewMinYMargin];
  
  [sipBox setAutoresizingMask:NSViewHeightSizable];
  [sipDisclosure setAutoresizingMask:NSViewMinYMargin];
  [sipTitle setAutoresizingMask:NSViewMinYMargin];
  
  [self resizeContentView];
  
  [networkBox setAutoresizingMask:NSViewHeightSizable];
  
  [h323Box setAutoresizingMask:NSViewMaxYMargin];
  [h323Disclosure setAutoresizingMask:NSViewMaxYMargin];
  [h323Title setAutoresizingMask:NSViewMaxYMargin];
  
  [sipBox setAutoresizingMask:NSViewMaxYMargin];
  [sipDisclosure setAutoresizingMask:NSViewMaxYMargin];
  [sipTitle setAutoresizingMask:NSViewMaxYMargin];
  
  if (showSIPDetails == YES) {
    [sipBox setHidden:NO];
  }
  
  [self _storeDetailStatus];
}

#pragma mark -
#pragma mark Private Methods

- (void)_updateNetworkStatus:(NSNotification *)notif
{
  XMUtils *utils = [XMUtils sharedInstance];
  
  NSArray *networkInterfaces = [utils networkInterfaces];
  unsigned interfaceCount = [networkInterfaces count];
  
  if (interfaceCount == 0) {
    [ipAddressesField setStringValue:@""];
    [ipAddressStatusImage setImage:[NSImage imageNamed:@"status_red"]];
    
    addressExtraHeight = 0;
    [self resizeContentView];
    
    [natTypeField setStringValue:@""];
    [natTypeStatusImage setImage:[NSImage imageNamed:@"status_red"]];
    
    return;
  }
  
  NSMutableString *ipAddressString = [[NSMutableString alloc] initWithCapacity:30];
  XMNetworkInterface *iface = (XMNetworkInterface *)[networkInterfaces objectAtIndex:0];
  [ipAddressString appendString:[iface ipAddress]];
  [ipAddressString appendString:@" ("];
  [ipAddressString appendString:[iface name]];
  [ipAddressString appendString:@")"];
  
  for (unsigned i = 1; i < interfaceCount; i++) {
    iface = (XMNetworkInterface *)[networkInterfaces objectAtIndex:i];
    [ipAddressString appendString:@"\n"];
    [ipAddressString appendString:[iface ipAddress]];
    [ipAddressString appendString:@" ("];
    [ipAddressString appendString:[iface name]];
    [ipAddressString appendString:@")"];
  }
  
  // calculate extra height for the additional interfaces
  addressExtraHeight = (interfaceCount-1)*XM_IP_ADDRESSES_TEXT_FIELD_HEIGHT;
  
  NSString *publicAddress = [utils publicAddress];
    
  // display public address only if local addresses don't contain the public address
  // (i.e. behind a NAT)
  if (publicAddress != nil && ![utils isLocalAddress:publicAddress]) {
    [ipAddressString appendString:@"\n"];
    [ipAddressString appendString:publicAddress];
    [ipAddressString appendString:NSLocalizedString(@"XM_EXTERNAL_ADDRESS_SUFFIX", @"")];
    addressExtraHeight += XM_IP_ADDRESSES_TEXT_FIELD_HEIGHT;
  }
  
  [ipAddressesField setStringValue:ipAddressString];
  [ipAddressesField setToolTip:ipAddressString];
  [ipAddressString release];
  [ipAddressStatusImage setImage:[NSImage imageNamed:@"status_green"]];
  
  // Determining the NAT Type
  XMNATType natType = [utils natType];
  NSString *natTypeString = XMNATTypeString(natType);
  [natTypeField setStringValue:natTypeString];
  
  if (natType == XMNATType_Error || natType == XMNATType_BlockedNAT) {
    [natTypeStatusImage setImage:[NSImage imageNamed:@"status_red"]];
  } else if (natType == XMNATType_SymmetricNAT || natType == XMNATType_SymmetricFirewall || natType == XMNATType_PartialBlockedNAT) {
    [natTypeStatusImage setImage:[NSImage imageNamed:@"status_yellow"]];
  } else {
    [natTypeStatusImage setImage:[NSImage imageNamed:@"status_green"]];
  }
  
  [self resizeContentView];
}

- (void)_updateProtocolStatus:(NSNotification *)notif
{
  XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
  XMLocation *activeLocation = [preferencesManager activeLocation];
  XMCallManager *callManager = [XMCallManager sharedInstance];
  
  // Change the autoresize behavious
  [networkBox setAutoresizingMask:NSViewMinYMargin];
  
  // setting up the H.323 info
  h323AliasesExtraHeight = 0;
  [terminalAliasViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
  [terminalAliasViews removeAllObjects];
  
  if ([activeLocation enableH323] == YES) {
    [h323StatusField setStringValue:NSLocalizedString(@"Online", @"")];
    [h323StatusImage setImage:[NSImage imageNamed:@"status_green"]];
    
    if ([callManager isH323Enabled] == YES) {
      unsigned h323AccountTag = [activeLocation h323AccountTag];
      if (h323AccountTag != 0) {
        XMH323Account *account = [preferencesManager h323AccountWithTag:h323AccountTag];
        NSString *terminalAlias = [account terminalAlias1];
        NSString *gatekeeper = [callManager gatekeeperName];
        
        if (gatekeeper != nil) {
          
          [gatekeeperField setStringValue:gatekeeper];
          [gatekeeperStatusImage setImage:[NSImage imageNamed:@"status_green"]];
          
          NSArray *aliases = [callManager terminalAliases];
          unsigned numAliases = [aliases count];
          for (unsigned i = 0; i < numAliases; i++) {
            NSString *alias = (NSString *)[aliases objectAtIndex:i];
            if (i == 0) {
              [terminalAliasField setTextColor:[NSColor controlTextColor]];
              [terminalAliasField setStringValue:alias];
            } else {
              h323AliasesExtraHeight += XM_ALIASES_TEXT_FIELD_HEIGHT;
              NSTextField *textField = [self _copyTextField:terminalAliasField];
              NSRect frame = [textField frame];
              frame.origin.y -= (i*XM_ALIASES_TEXT_FIELD_HEIGHT);
              [textField setFrame:frame];
              [h323Box addSubview:textField];
              [textField setStringValue:alias];
              [terminalAliasViews addObject:textField];
              [textField release];
            }
          }
        } else {
          [gatekeeperField setStringValue:NSLocalizedString(@"XM_INFO_MODULE_REG_FAILURE", @"")];
          [gatekeeperStatusImage setImage:[NSImage imageNamed:@"status_red"]];
          [terminalAliasField setTextColor:[NSColor disabledControlTextColor]];
          [terminalAliasField setStringValue:terminalAlias];
        }
      } else {
        [gatekeeperField setStringValue:NSLocalizedString(@"XM_INFO_MODULE_NO_REG", @"")];
        [gatekeeperStatusImage setImage:nil];
        [terminalAliasField setStringValue:@""];
      }
    } else {
      [h323StatusField setStringValue:NSLocalizedString(@"XM_INFO_MODULE_PROTOCOL_FAILURE", @"")];
      [h323StatusImage setImage:[NSImage imageNamed:@"status_red"]];
      [gatekeeperField setStringValue:@""];
      [gatekeeperStatusImage setImage:nil];
      [terminalAliasField setStringValue:@""];
    }
  } else {
    [h323StatusField setStringValue:NSLocalizedString(@"XM_INFO_MODULE_NO_PROTOCOL", @"")];
    [h323StatusImage setImage:nil];
    [gatekeeperField setStringValue:@""];
    [gatekeeperStatusImage setImage:nil];
    [terminalAliasField setStringValue:@""];
  }
  
  // Resize the H.323 box
  [h323Box setAutoresizingMask:NSViewHeightSizable];
  [h323Disclosure setAutoresizingMask:NSViewMinYMargin];
  [h323Title setAutoresizingMask:NSViewMinYMargin];
  
  [sipBox setAutoresizingMask:NSViewMaxYMargin];
  [sipDisclosure setAutoresizingMask:NSViewMaxYMargin];
  [sipTitle setAutoresizingMask:NSViewMaxYMargin];
  
  [self resizeContentView];
  
  // setting up the SIP info
  sipRegistrationsExtraHeight = 0;
  [registrationViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
  [registrationViews removeAllObjects];
  
  if ([activeLocation enableSIP] == YES) {
    if ([callManager isSIPEnabled] == YES) {
      [sipStatusField setStringValue:@"Online"];
      [sipStatusImage setImage:[NSImage imageNamed:@"status_green"]];
      
      NSArray *sipAccountTags = [activeLocation sipAccountTags];
      unsigned numSIPAccounts = [sipAccountTags count];
      if ([sipAccountTags count] != 0) {
        for (unsigned i = 0; i < numSIPAccounts; i++) {
          unsigned tag = [(NSNumber *)[sipAccountTags objectAtIndex:i] unsignedIntValue];
          XMSIPStatusCode status = [callManager sipRegistrationStatusAtIndex:i];
          XMSIPAccount *account = [preferencesManager sipAccountWithTag:tag];
          NSString *aor = [account addressOfRecord];
          BOOL okay = (status == XMSIPStatusCode_Successful_OK ? YES : NO);
          if (i == 0) {
            [registrationField setStringValue:aor];
            if (okay) {
              [registrationStatusImage setImage:[NSImage imageNamed:@"status_green"]];
            } else {
              [registrationStatusImage setImage:[NSImage imageNamed:@"status_red"]];
            }
          } else {
            sipRegistrationsExtraHeight += XM_REGISTRATION_INFO_HEIGHT;
            NSTextField *textField = [self _copyTextField:registrationField];
            NSRect frame = [textField frame];
            frame.origin.y -= (i*XM_REGISTRATION_INFO_HEIGHT);
            [textField setFrame:frame];
            [sipBox addSubview:textField];
            [textField setStringValue:aor];
            [registrationViews addObject:textField];
            [textField release];
            
            NSImageView *imageView = [self _copyImageView:registrationStatusImage];
            frame = [imageView frame];
            frame.origin.y -= (i*XM_REGISTRATION_INFO_HEIGHT);
            [imageView setFrame:frame];
            [sipBox addSubview:imageView];
            if (okay) {
              [imageView setImage:[NSImage imageNamed:@"status_green"]];
            } else {
              [imageView setImage:[NSImage imageNamed:@"status_red"]];
            }
            [registrationViews addObject:imageView];
            [imageView release];
          }
        }
      } else {
        [registrationField setStringValue:NSLocalizedString(@"XM_INFO_MODULE_NO_REG", @"")];
        [registrationStatusImage setImage:nil];
      }
    } else {
      [sipStatusField setStringValue:NSLocalizedString(@"XM_INFO_MODULE_PROTOCOL_FAILURE", @"")];
      [sipStatusImage setImage:[NSImage imageNamed:@"status_red"]];
      [registrationField setStringValue:@""];
      [registrationStatusImage setImage:nil];
    }
  } else {
    [sipStatusField setStringValue:NSLocalizedString(@"XM_INFO_MODULE_NO_PROTOCOL", @"")];
    [sipStatusImage setImage:nil];
    [registrationField setStringValue:@""];
    [registrationStatusImage setImage:nil];
  }
  
  // Now resize the SIP content view
  [h323Box setAutoresizingMask:NSViewMinYMargin];
  [sipBox setAutoresizingMask:NSViewHeightSizable];
  [sipDisclosure setAutoresizingMask:NSViewMinYMargin];
  [sipTitle setAutoresizingMask:NSViewMinYMargin];
  
  [self resizeContentView];
  
  // Restore the default autoresize values
  [networkBox setAutoresizingMask:NSViewHeightSizable];
  
  [h323Box setAutoresizingMask:NSViewMaxYMargin];
  [h323Disclosure setAutoresizingMask:NSViewMaxYMargin];
  [h323Title setAutoresizingMask:NSViewMaxYMargin];
  
  [sipBox setAutoresizingMask:NSViewMaxYMargin];
  [sipDisclosure setAutoresizingMask:NSViewMaxYMargin];
  [sipTitle setAutoresizingMask:NSViewMaxYMargin];
}

- (void)_storeDetailStatus
{
  unsigned status = 0;
  
  if (showH323Details == YES) {
    status += XM_SHOW_H323_DETAILS;
  }
  if (showSIPDetails == YES) {
    status += XM_SHOW_SIP_DETAILS;
  }
  
  [[NSUserDefaults standardUserDefaults] setInteger:status forKey:XMKey_InfoModuleDetailStatus];
}

- (NSTextField *)_copyTextField:(NSTextField *)_textField
{
  NSRect frame = [_textField frame];
  NSTextField *textField = [[NSTextField alloc] initWithFrame:frame];
  [textField setEditable:NO];
  [textField setDrawsBackground:NO];
  [textField setBordered:NO];
  [textField setFont:[_textField font]];
  [textField setAutoresizingMask:[_textField autoresizingMask]];
  
  return textField;
}

- (NSImageView *)_copyImageView:(NSImageView *)_imageView
{
  NSRect frame = [_imageView frame];
  NSImageView *imageView = [[NSImageView alloc] initWithFrame:frame];
  [imageView setImageFrameStyle:[_imageView imageFrameStyle]];
  [imageView setImageAlignment:[_imageView imageAlignment]];
  [imageView setImageScaling:[_imageView imageScaling]];
  [imageView setEditable:NO];
  [imageView setAutoresizingMask:[_imageView autoresizingMask]];
  
  return imageView;
}

@end
