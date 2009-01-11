/*
 * $Id: XMAudioManager.h,v 1.11 2009/01/11 18:58:26 hfriederich Exp $
 *
 * Copyright (c) 2005-2009 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2009 Hannes Friederich. All rights reserved.
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
  
@private
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
  
  BOOL doesMeasureSignalLevels;
  double inputLevel;
  double outputLevel;
  
  BOOL doesRunAudioTest;
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
- (BOOL)mutesInput;
- (BOOL)setMutesInput:(BOOL)muteVolume;

- (BOOL)canAlterOutputVolume;
- (unsigned)outputVolume;
- (BOOL)setOutputVolume:(unsigned)vol;
- (BOOL)mutesOutput;
- (BOOL)setMutesOutput:(BOOL)muteVolume;

/**
 * Getting information about input/output levels
 **/
- (BOOL)doesMeasureSignalLevels;
- (void)setDoesMeasureSignalLevels:(BOOL)flag;
- (double)inputLevel;
- (double)outputLevel;

/**
 * Starting / stopping the audio test
 * Note that this test is only available while not
 * being in a call.
 * Recorded audio will be delayed by 'delay' seconds
 * before being outputted again.
 * An audio test will be aborted automatically when
 * a call is established.
 **/
- (void)startAudioTestWithDelay:(unsigned)delay;
- (void)stopAudioTest;
- (BOOL)doesRunAudioTest;

@end

#endif // __XM_AUDIO_MANAGER_H__