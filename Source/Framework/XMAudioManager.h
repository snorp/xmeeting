/*
 * $Id: XMAudioManager.h,v 1.5 2006/03/14 23:05:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_AUDIO_MANAGER_H__
#define __XM_AUDIO_MANAGER_H__

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudio.h>

/**
 * XMAudioManager provides the interface for accessing all audio-related
 * informations.
 * This manager provides a list of available audio devices, selected devices
 * and volume control.
 **/
@interface XMAudioManager : NSObject {
	NSArray *inputDevices;
	NSString *selectedInputDevice;
	AudioDeviceID selectedInputDeviceID;
	BOOL selectedInputDeviceIsMuted;
	
	NSArray *outputDevices;
	NSString *selectedOutputDevice;
	AudioDeviceID selectedOutputDeviceID;
	BOOL selectedOutputDeviceIsMuted;
	
	NSString *noDeviceName;
	NSString *unknownDeviceName;
}

/**
 * Returns the shared singleton instance of XMAudioManager
 **/
+ (XMAudioManager *)sharedInstance;

/**
 * makes XMAudioManager to refresh it's device lists
 * in order to detect newly attached devices or the 
 * removal of devices
 **/
- (void)updateDeviceLists;

/**
 * lists the available devices
 **/
- (NSArray *)inputDevices;
- (NSString *)defaultInputDevice;

- (NSArray *)outputDevices;
- (NSString *)defaultOutputDevice;

/**
 * Controlling selected devices
 **/
- (NSString *)selectedInputDevice;
- (BOOL)setSelectedInputDevice:(NSString *)str;
- (NSString *)selectedOutputDevice;
- (BOOL)setSelectedOutputDevice:(NSString *)str;

/**
 * Controlling volume
 * Volume is between 0 and 100
 **/
- (BOOL)canAlterInputVolume;
- (unsigned)inputVolume;
- (BOOL)setInputVolume:(unsigned)vol;
- (BOOL)mutesInputVolume;
- (BOOL)setMutesInputVolume:(BOOL)muteVolume;

- (BOOL)canAlterOutputVolume;
- (unsigned)outputVolume;
- (BOOL)setOutputVolume:(unsigned)vol;
- (BOOL)mutesOutputVolume;
- (BOOL)setMutesOutputVolume:(BOOL)muteVolume;

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