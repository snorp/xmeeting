/*
 * $Id: XMVolumeControl.cpp,v 1.1 2005/02/11 12:58:44 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include "XMVolumeControl.h"
#include "XMCallbackBridge.h"

XMSoundChannel::XMSoundChannel(const PString &device,
							   PSoundChannel::Directions dir,
							   unsigned numChannels,
							   unsigned sampleRate,
							   unsigned bitsPerSample)
: PSoundChannelCoreAudio(device, dir, numChannels, sampleRate, bitsPerSample)
{
	OSStatus err;
	
	err = AudioDeviceAddPropertyListener(mDeviceID, 
										 1, 	
										 kAudioPropertyWildcardSection,
										 kAudioDevicePropertyVolumeScalar, 
										 XMVolumeChangePropertyListener,
										 (void *)this);
}

XMSoundChannel::~XMSoundChannel()
{
	OSStatus err;
	
	err = AudioDeviceRemovePropertyListener(mDeviceID, 
											1, 	
											kAudioPropertyWildcardSection,
											kAudioDevicePropertyVolumeScalar, 
											VolumeChangePropertyListener);
}

OSStatus XMSoundChannel::XMVolumeChangePropertyListener(AudioDeviceID id, 
										UInt32 chan,
										Boolean isInput, 
										AudioDevicePropertyID propID, 
										void* user_data)
{
	XMSoundChannel *This = static_cast<XMSoundChannel*>(user_data);
	unsigned volume;
	
	This->GetVolume(volume);
	
	if(isInput)
	{
		audioInputVolumeDidChange(volume);
	}
	else
	{
		audioOutputVolumeDidChange(volume);
	}
	
	return noErr;
}

