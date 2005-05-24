/*
 * $Id: XMAudioManager.h,v 1.2 2005/05/24 15:21:01 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_AUDIO_MANAGER_H__
#define __XM_AUDIO_MANAGER_H__

#import <Foundation/Foundation.h>

/*
 * Notifications posted by XMAudioManager
 */
extern NSString *XMNotification_InputVolumeDidChange;
extern NSString *XMNotification_OutputVolumeDidChange;

/**
 * XMAudioManager provides the interface for accessing all audio-related
 * informations.
 * This manager provides a list of available audio devices, selected devices
 * and volume control.
 **/
@interface XMAudioManager : NSObject {
	NSArray *audioInputDevices;
	NSArray *audioOutputDevices;
	id delegate;
}

/*
 * Returns the shared singleton instance of XMAudioManager
 */
+ (XMAudioManager *)sharedInstance;

/*
 * makes XMAudioManager to refresh it's device lists
 * in order to detect newly attached devices or the 
 * removal of devices
 */
- (void)updateDeviceLists;

/*
 * lists the available devices
 */
- (NSArray *)inputDevices;
- (NSString *)defaultInputDevice;

- (NSArray *)outputDevices;
- (NSString *)defaultOutputDevice;

/*
 * Controlling audio input
 */
- (NSString *)selectedInputDevice;
- (void)setSelectedInputDevice:(NSString *)str;

// volume is between 0 and 100
- (unsigned)inputVolume;
- (void)setInputVolume:(unsigned)vol;

/*
 * Controlling audio output
 */
- (NSString *)selectedOutputDevice;
- (void)setSelectedOutputDevice:(NSString *)str;

// volume is between 0 and 100
- (unsigned)outputVolume;
- (void)setOutputVolume:(unsigned)vol;

@end

/**
 * Methods that a delegate may implement
 * If a delegate implements these methods, the XMAudioManager
 * automatically registers the delegate as an observer for these
 * notifications
 **/
@protocol XMAudioManagerDelegate

- (void)audioManagerInputVolumeDidChange:(NSNotification *)notif;
- (void)audioManagerOutputVolumeDidChange:(NSNotification *)notif;

@end

#endif // __XM_AUDIO_MANAGER_H__