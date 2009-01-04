/*
 * $Id: XMSetupAssistantModules.m,v 1.1 2009/01/04 17:16:33 hfriederich Exp $
 *
 * Copyright (c) 2009 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2009 Hannes Friederich. All rights reserved.
 */

#import "XMSetupAssistantModules.h"


@implementation XMSAEditIntroductionModule

- (NSArray *)editKeys
{
  return [NSArray array];
}

- (BOOL)isActiveForData:(id<XMSetupAssistantData>)data
{
  return YES;
}

- (NSString *)title
{
  return @"TEST1";
}

- (BOOL)showTitle
{
  return NO;
}

- (NSView *)contentView
{
  return contentView;
}

- (void)loadData:(id<XMSetupAssistantData>)data
{
}

- (void)saveData:(id<XMSetupAssistantData>)data
{
}

- (void)editData:(NSArray *)editKeys
{
}

@end

@implementation XMSAGeneralModule

- (NSArray *)editKeys
{
  return [NSArray array];
}

- (BOOL)isActiveForData:(id<XMSetupAssistantData>)data
{
  return YES;
}

- (NSString *)title
{
  return @"TEST2";
}

- (BOOL)showTitle
{
  return YES;
}

- (NSView *)contentView
{
  return contentView;
}

- (void)loadData:(id<XMSetupAssistantData>)data
{
}

- (void)saveData:(id<XMSetupAssistantData>)data
{
}

- (void)editData:(NSArray *)editKeys
{
}

@end

@implementation XMSALocationModule 

- (NSArray *)editKeys
{
  return [NSArray array];
}

- (BOOL)isActiveForData:(id<XMSetupAssistantData>)data
{
  return YES;
}

- (NSString *)title
{
  return @"TEST3";
}

- (BOOL)showTitle
{
  return YES;
}

- (NSView *)contentView
{
  return contentView;
}

- (void)loadData:(id<XMSetupAssistantData>)data
{
}

- (void)saveData:(id<XMSetupAssistantData>)data
{
}

- (void)editData:(NSArray *)editKeys
{
}

@end
