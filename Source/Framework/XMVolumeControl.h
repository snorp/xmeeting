/*
 * $Id: XMVolumeControl.h,v 1.1 2005/02/11 12:58:44 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

/**
 * This file is intended to provide audio volume-control functionnality
 * since this is too difficult to directly achieve via PWLib/OPAL.
 *
 * At the moment, this functionnality is implemented as a subclass
 * of PSoundChannelCoreAudio. However, it is planned to make
 * a dedicated implementation, removing the unnecessary overhead
 * of a fully opened PSoundChannel
 */

#ifndef __XM_VOLUME_CONTROL_H__
#define __XM_VOLUME_CONTROL_H__

#include <ptlib.h>
#include <ptlib/unix/ptlib/maccoreaudio.h>

class XMSoundChannel : public PSoundChannelCoreAudio
{
public:
	XMSoundChannel(const PString &device,
				   PSoundChannel::Directions dir,
				   unsigned numChannels,
				   unsigned sampleRate,
				   unsigned bitsPerSample);
	~XMSoundChannel();
	
	//BOOL GetVolume(unsigned & vol);
	
	static OSStatus XMVolumeChangePropertyListener(AudioDeviceID id, 
												   UInt32 chan,
												   Boolean isInput, 
												   AudioDevicePropertyID propID, 
												   void* inUserData);
};

#endif // __XM_VOLUME_CONTROL_H__