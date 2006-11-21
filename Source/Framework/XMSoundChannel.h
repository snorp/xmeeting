/*
 * $Id: XMSoundChannel.h,v 1.7 2006/11/21 10:42:25 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Andreas Fenkart, Hannes Friederich. All rights reserved.
 */

#ifndef __XM_SOUND_CHANNEL_H__
#define __XM_SOUND_CHANNEL_H__

#define __OPENTRANSPORTPROVIDERS__

#include <CoreAudio/CoreAudio.h>
#include <AudioToolbox/AudioToolbox.h>
#include <AudioUnit/AudioUnit.h>

// needed by lists.h of pwlib, unfortunately also defined in previous
// includes from Apple
#undef nil

// static loading of plugins
#define P_FORCE_STATIC_PLUGIN

#include <ptlib.h>
#include <ptlib/sound.h>

class XMCircularBuffer;

class XMSoundChannel : public PSoundChannel
{
	PCLASSINFO(XMSoundChannel, PSoundChannel);
	
public:

#pragma mark -
#pragma mark Static XMeeting Methods
	
	/**
	 * Does necessary initialization
	 **/
	static void Init();
	
	/**
	 * Closes the devics if needed
	 **/
	static void DoClose();
	
	/**
	 * Static Methods for changing devices / mute
	 **/
	static void SetPlayDevice(unsigned int deviceID);
	static void SetPlayDeviceMuted(BOOL muteFlag);
	static void SetRecordDevice(unsigned int deviceID);
	static void SetRecordDeviceMuted(BOOL muteFlag);
	
	/**
	 * Signal level metering
	 **/
	static void SetMeasureSignalLevels(BOOL flag);
	
	/**
	 * Audio Recording
	 **/
	static void SetRecordAudio(BOOL flag);
	
	/**
	 * Instructs both play and record channel to immediately stop playing.
	 * Needed to avoid the output unit to produce noise when the connection
	 * is closed
	 **/
	static void StopChannels();

#pragma mark -
#pragma mark Public Methods
	
	/**
	 * Constructors
	 **/
	XMSoundChannel(); // This constructor is used by PWLib
	XMSoundChannel(const PString & device,
				   PSoundChannel::Directions dir,
				   unsigned numChannels,
				   unsigned sampleRate,
				   unsigned bitsPerSample);
	~XMSoundChannel();
	
	/**
	 * Returns just one device (XMSoundChannelDevice)
	 * to allow the device selection while the device is running
	 **/
	static PString GetDefaultDevice(PSoundChannel::Directions direction);
	static PStringList GetDeviceNames(PSoundChannel::Directions direction);
	
	/**
	 * Opens the device, making it ready to play
	 * Please note that the device does not work properly
	 * until SetBuffers() is also called after Open()
	 **/
	virtual BOOL Open(const PString & device,
					  PSoundChannel::Directions direction,
					  unsigned numChannels = 1,
					  unsigned sampleRate = 8000,
					  unsigned bitsPerSample = 16);
	virtual BOOL IsOpen() const;
	
	// Accessing the attributes
	virtual unsigned GetChannels() const;
	virtual unsigned GetSampleRate() const;
	virtual unsigned GetSampleSize() const;
	virtual BOOL SetFormat(unsigned numChannels = 1,
						   unsigned sampleRate = 8000,
						   unsigned bitsPerSample = 16);
	
	
	virtual BOOL GetBuffers(PINDEX & size,
							PINDEX & count);
	virtual BOOL SetBuffers(PINDEX size,
							PINDEX count = 2);
	
	// Performing I/O
	virtual BOOL Read(void *buffer, PINDEX length);
	virtual PINDEX GetLastReadCount() const;
	virtual BOOL Write(const void *buffer, PINDEX length);
	
	virtual BOOL StartRecording();
	virtual BOOL IsRecordBufferFull();
	virtual BOOL AreAllRecordBuffersFull();

#pragma mark -
#pragma mark Unimplemented Methods
	
	/**
	 * Uninplemented PSoundChannel methods
	 **/
	virtual BOOL Abort();
	virtual BOOL GetVolume(unsigned & volume);
	virtual BOOL SetVolume(unsigned volume);
	virtual BOOL PlaySound(const PSound & sound, BOOL wait);
	virtual BOOL PlayFile(const PFilePath & file, BOOL wait);
	virtual BOOL HasPlayCompleted();
	virtual BOOL WaitForPlayCompletion();
	virtual BOOL RecordSound(PSound & sound);
	virtual BOOL RecordFile(const PFilePath & file);
	virtual BOOL WaitForRecordBufferFull();
	virtual BOOL WaitForAllRecordBuffersFull();
	
private:

#pragma mark -
#pragma mark Private Methods
	
	void CommonConstruct();
	BOOL OpenDevice(AudioDeviceID deviceID,
					unsigned numChannels = 1,
					unsigned sampleRate = 8000,
					unsigned bitsPerSample = 16);
	void CloseDevice();
	void SetDeviceMuted(BOOL muteFlag);
	void Start();
	void Stop();
	void Restart(AudioDeviceID deviceID, BOOL startIfNeeded = TRUE);
	OSStatus StartAudioConversion();
	OSStatus StopAudioConversion();
	OSStatus SetupInputUnit();
	OSStatus SetupOutputUnit();
	OSStatus SetupAdditionalRecordBuffers();
	OSStatus SetDeviceAsCurrent();
	OSStatus EnableIO();
	OSStatus MatchHALInputFormat();
	OSStatus MatchHALOutputFormat();
	OSStatus CallbackSetup();
	static OSStatus ComplexBufferFillPlayback(OpaqueAudioConverter*,
											  UInt32*,
											  AudioBufferList*,
											  AudioStreamPacketDescription**,
											  void *);
	static OSStatus ComplexBufferFillRecord(OpaqueAudioConverter*,
											UInt32*,
											AudioBufferList*,
											AudioStreamPacketDescription**,
											void *);
	static OSStatus PlayRenderProc(void *inRefCon,
								   AudioUnitRenderActionFlags *ioActionFlags,
								   const struct AudioTimeStamp *timeStamp,
								   UInt32 inBusNumber,
								   UInt32 inNumberFrames,
								   struct AudioBufferList *ioData);
	static OSStatus RecordProc(void *inRefCon,
							   AudioUnitRenderActionFlags *ioActionFlags,
							   const AudioTimeStamp *inTimeStamp,
							   UInt32 inBusNumber,
							   UInt32 inNumberFrames,
							   AudioBufferList *ioData);
	
#pragma mark Instance Variables
	
	enum State{
		init_,
		open_,
		format_set_,
		buffer_set_,
		running_
	};
	
	// Instance variables
	Directions direction;
	State state;
	BOOL isMuted;
	AudioUnit mAudioUnit;
	AudioDeviceID mDeviceID;
	AudioStreamBasicDescription hwASBD, pwlibASBD;
	
	AudioConverterRef converter;
	XMCircularBuffer *mCircularBuffer;
	
	Float64 rateTimes8kHz;
	
	PINDEX bufferSizeBytes;
	PINDEX bufferCount;
	
	/*
	 * Buffer to hold data that are passed to the converter.
	 * Separate means independant of the circular_buffer
	 */
	char *converter_buffer;
	UInt32 converter_buffer_size;
	
	/* ==========================================================
	 * Variables used only by the Recorder to circumvent
	 * the inappropriaty control flow of the pull model
	 */
	/** Buffers to capture raw data from the microphone */
	XMCircularBuffer* mInputCircularBuffer;
	AudioBufferList* mInputBufferList;
	UInt32 mRecordInputBufferSize;
	
	AudioBufferList *mOutputBufferList;
	UInt32 mRecordOutputBufferSize;
	
	BOOL isInputProxy;
	
	PMutex editMutex;
	
};

#endif // __XM_SOUND_CHANNEL_H__

