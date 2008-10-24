/*
 * $Id: XMSoundChannel.h,v 1.12 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Andreas Fenkart, Hannes Friederich. All rights reserved.
 */

#ifndef __XM_SOUND_CHANNEL_H__
#define __XM_SOUND_CHANNEL_H__

#define __OPENTRANSPORTPROVIDERS__

#include <CoreAudio/CoreAudio.h>
#include <AudioToolbox/AudioToolbox.h>
#include <AudioUnit/AudioUnit.h>

// needed by lists.h of ptlib, unfortunately also defined in previous
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
  static void SetPlayDeviceMuted(bool muteFlag);
  static void SetRecordDevice(unsigned int deviceID);
  static void SetRecordDeviceMuted(bool muteFlag);
	
  /**
   * Signal level metering
   **/
  static void SetMeasureSignalLevels(bool flag);
	
  /**
   * Audio Recording
   **/
  static void SetRecordAudio(bool flag);
	
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
	XMSoundChannel(); // This constructor is used by PTLib
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
  virtual bool Open(const PString & device,
                    PSoundChannel::Directions direction,
                    unsigned numChannels = 1,
                    unsigned sampleRate = 8000,
                    unsigned bitsPerSample = 16);
  virtual bool IsOpen() const;
	
  // Accessing the attributes
  virtual unsigned GetChannels() const;
  virtual unsigned GetSampleRate() const;
  virtual unsigned GetSampleSize() const;
  virtual bool SetFormat(unsigned numChannels = 1,
                         unsigned sampleRate = 8000,
                         unsigned bitsPerSample = 16);
	
	
  virtual bool GetBuffers(PINDEX & size,
                          PINDEX & count);
  virtual bool SetBuffers(PINDEX size,
                          PINDEX count = 2);
	
  // Performing I/O
  virtual bool Read(void *buffer, PINDEX length);
  virtual PINDEX GetLastReadCount() const;
  virtual bool Write(const void *buffer, PINDEX length);
	
  virtual bool StartRecording();
  virtual bool IsRecordBufferFull();
  virtual bool AreAllRecordBuffersFull();

#pragma mark -
#pragma mark Unimplemented Methods
	
  /**
   * Uninplemented PSoundChannel methods
   **/
  virtual bool Abort();
  virtual bool GetVolume(unsigned & volume);
  virtual bool SetVolume(unsigned volume);
  virtual bool PlaySound(const PSound & sound, bool wait);
  virtual bool PlayFile(const PFilePath & file, bool wait);
  virtual bool HasPlayCompleted();
  virtual bool WaitForPlayCompletion();
  virtual bool RecordSound(PSound & sound);
  virtual bool RecordFile(const PFilePath & file);
  virtual bool WaitForRecordBufferFull();
  virtual bool WaitForAllRecordBuffersFull();
	
private:

#pragma mark -
#pragma mark Private Methods
    
  static inline unsigned min(unsigned a, unsigned b);
	
  void CommonConstruct();
  bool OpenDevice(AudioDeviceID deviceID,
                  unsigned numChannels = 1,
                  unsigned sampleRate = 8000,
                  unsigned bitsPerSample = 16);
  void CloseDevice();
  void SetDeviceMuted(bool muteFlag);
  void Start();
  void Stop();
  void Restart(AudioDeviceID deviceID, bool startIfNeeded = true);
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
	
#pragma mark -
#pragma mark Instance Variables
	
  enum State{
    init_,
    open_,
    format_set_,
    buffer_set_,
    running_
  };
	
  // Instance variables
  PMutex editMutex;
  bool isInputProxy;
    
  Directions direction;
  State state;
  bool isMuted;
  AudioUnit mAudioUnit;
  AudioDeviceID mDeviceID;
  AudioStreamBasicDescription hwASBD, ptlibASBD;
	
  AudioConverterRef converter;
  XMCircularBuffer *mCircularBuffer;
	
  Float64 rateTimes8kHz;
	
	unsigned bufferSizeBytes;
	unsigned bufferCount;
    
  unsigned muteBytesRead;
  struct timeval muteStartTime;
	
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
	
  AudioBufferList *mOutputBufferList;
  UInt32 mRecordOutputBufferSize;
	
};

#endif // __XM_SOUND_CHANNEL_H__

