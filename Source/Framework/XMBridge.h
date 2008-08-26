/*
 * $Id: XMBridge.h,v 1.48 2008/08/26 08:14:07 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

/**
* The purpose of XMBridge is to provide a clean bridge between
 * the objective-c world using the Cocoa framework and the c++ world,
 * using PWLib / OPAL.
 *
 * Mixing the two languages itself isn't the problem, all one has to do
 * is to use objective-c++. However, objective-c++ itself looks quite ugly
 * and its usage should me minimized.
 * The real problem is the inclusion of headers. PWLib does redefine a
 * couple of stuff defined in Cocoa and adjusting the headers in PWLib
 * is just too painful.
 *
 * Therefore, this file provides a couple of c++ functions which can
 * safely be called by the Cocoa-part of the code and which bridge over
 * to PWLib/OPAL. This approach does work around big hacks and has the
 * advantage that it generates a clear interface centered in one file
 * without adding too much overhead.
 * However, this apporach requires a good MemoryManagement policy in order not
 * to leak memory. Above each function is defined who is
 * responsible for the memory management if there is any memory to manage.
 **/

#ifndef __XM_BRIDGE_H__
#define __XM_BRIDGE_H__

#include "XMTypes.h"

#ifdef __cplusplus
extern "C" {
#endif
  
#pragma mark Init & Startup/Stop functions
  
  /** 
   * Calling this function initializes the whole OPAL system
   * and makes it ready to be used.
   * It is safe to call initOPAL() multiple times.
   **/
  void _XMInitSubsystem(const char *pTracePath);
	
  /**
   * Closes the OPAL system
   **/
  void _XMCloseSubsystem();
  
#pragma mark -
#pragma mark General Setup Functions
  
  /**
   * sets the user name to be used.
   **/
  void _XMSetUserName(const char *string);
  
  /**
   * Returns the current user name
   * The value is obtained call-by-reference.
   **/
  const char *_XMGetUserName();
  
#pragma mark -
#pragma mark Network setup functions
  
  /**
   * sets the bandwidth limit to the value as specified
   **/
  void _XMSetBandwidthLimit(unsigned limit);
  
  /**
   * Sets the NAT information to use to establish
   * NAT traversal
   **/
  void _XMSetNATInformation(const char * const * stunServers,
                            unsigned stunServerCount,
                            const char *translationAddress,
                            bool networkStatusChanged);
  /**
   * defines which port ranges to use to establish
   * the media streams
   **/
  void _XMSetPortRanges(unsigned int udpPortMin,
                        unsigned int udpPortMax,
                        unsigned int tcpPortMin,
                        unsigned int tcpPortMax,
                        unsigned int rtpPortMin,
                        unsigned int rtpPortMax);
  
  /**
   * Called when the available network interfaces change,
   * allowing it to re-do registrations etc
   **/
  void _XMHandleNetworkConfigurationChange();
  
#pragma mark -
#pragma mark Audio Functions
  
  void _XMSetSelectedAudioInputDevice(unsigned int device);
  void _XMSetMuteAudioInputDevice(bool muteFlag);
  
  void _XMSetSelectedAudioOutputDevice(unsigned int device);
  void _XMSetMuteAudioOutputDevice(bool muteFlag);
  
  void _XMSetMeasureAudioSignalLevels(bool flag);
  void _XMSetRecordAudio(bool flag);
  
  void _XMSetAudioFunctionality(bool enableSilenceSuppression, bool enableEchoCancellation, unsigned packetTime);
  void _XMStopAudio();
  
  void _XMStartAudioTest(unsigned delay);
  void _XMStopAudioTest();
  
#pragma mark -
#pragma mark Video Setup Functions
  
  void _XMSetEnableVideo(bool enableVideo);
  
  void _XMSetEnableH264LimitedMode(bool enableH264LimitedMode);
  
#pragma mark -
#pragma mark Codec Functions
  
  /**
   * Sets the ordered & disabled codec lists appropriately
   **/
  void _XMSetCodecs(const char * const * orderedCodecs, unsigned orderedCodecCount,
                    const char * const * disabledCodecs, unsigned disabledCodecCount);
  
#pragma mark -
#pragma mark H.323 Setup Functions
  
  /**
   * makes the H.323 system listen and thereby ready for calls
   **/
  bool _XMEnableH323(bool flag);
  
  /**
   * Returns whether H.323 is currently enabled or not
   **/
  bool _XMIsH323Enabled();
  
  /**
   * enables/disables FastStart and H.245 tunneling through H.323
   **/
  void _XMSetH323Functionality(bool enableFastStart, bool enableH245Tunnel);
  
  /**
    * sets up the Gatekeeper. If all terminalAlias1 is NULL, no Gatekeeper is used
   **/
  void _XMSetGatekeeper(const char *address, 
                        const char *terminalAlias1, 
                        const char *terminalAlias2,
                        const char *password);
  
  /**
   * reports whether we are registered at a gk or not
   **/
  bool _XMIsRegisteredAtGatekeeper();
  
#pragma mark -
#pragma mark SIP Setup Functions
  
  bool _XMEnableSIPListeners(bool enable);
  
  bool _XMIsSIPEnabled();
  
  /* Returns if the proxy information changed or not */
  bool _XMSetSIPProxy(const char *host,
                      const char *username,
                      const char *password);
  
  void _XMPrepareRegistrationSetup(bool proxyChanged);
  void _XMUseRegistration(const char *domain,
                          const char *username,
                          const char *authorizationUsername,
                          const char *password,
                          bool proxyChanged);
  void _XMFinishRegistrationSetup(bool proxyChanged);
  
  bool _XMIsSIPRegistered();
  
#pragma mark -
#pragma mark Call Management functions
  
  // This function causes the OPAL system to call the specified
  // remote party, using the specified protocol.
  // The return value is the callID for this call, or zero if the call
  // failed. A non-zero return value does not mean that the call was 
  // successful in itself, only that the attempt to call the remote
  // party was successful. The result of the call will then be reported
  // back through callbacks.
  // In case the initiation of the call failed, the reason will be passed
  // back through failReason
  unsigned _XMInitiateCall(XMCallProtocol protocol, const char *remoteParty, 
                           const char *origAddressString, XMCallEndReason *failReason);
  
  // Causes the OPAL system to accept the incoming call
  void _XMAcceptIncomingCall(unsigned callID);
  
  // Causes the OPAL system to reject the incomgin call
  void _XMRejectIncomingCall(unsigned callID);
  
  // Causes the OPAL system to clear the existing call
  void _XMClearCall(unsigned callID);
  
  // These functions provide additional information about the remote party. 
  // Note that calling this function is only safe when the call is established
  // Before calling XMGetCallInformation(), the call information has to be locked.
  // Afterwards, the call information has to be unlocked again.
  // Dereferencing the pointers after the call information has been unlocked is not
  // safe!
  void _XMLockCallInformation();
  void _XMUnlockCallInformation();
  void _XMGetCallInformation(unsigned callID,
                             const char** remoteName, 
                             const char** remoteNumber,
                             const char** remoteAddress, 
                             const char** remoteApplication);
  
  // Provides the relevant statistics data
  void _XMGetCallStatistics(unsigned callID,
                            XMCallStatisticsRecord *callStatistics);
  
#pragma mark -
#pragma mark InCall Functions
  
  bool _XMSetUserInputMode(XMUserInputMode userInputMode);
  bool _XMSendUserInputTone(unsigned callID, const char tone);
  bool _XMSendUserInputString(unsigned callID, const char *string);
  bool _XMStartCameraEvent(unsigned callID, XMCameraEvent cameraEvent);
  void _XMStopCameraEvent(unsigned callID);
  
#pragma mark -
#pragma mark MediaTransmitter Functions
  
  void _XMSetTimeStamp(unsigned sessionID, unsigned timeStamp);
  void _XMAppendData(unsigned sessionID, void *data, unsigned length);
  void _XMSendPacket(unsigned sessionID, bool setMarkerBit);
  void _XMDidStopTransmitting(unsigned sessionID);
  
#pragma mark -
#pragma mark Message Logging
  
  void _XMLogMessage(const char *message);
  
#pragma mark -
#pragma mark MediaFormat Functions
  
  bool _XMHasCodecInstalled(XMCodecIdentifier codecIdentifier);
  const char *_XMMediaFormatForCodecIdentifier(XMCodecIdentifier codecIdentifier);
  
#pragma mark -
#pragma mark Constants
  
/**
 * Audio Device Names used within OPAL
 **/
#define XMSoundChannelDevice "XMSoundChannelDevice"
#define XMInputSoundChannelDevice "XMInputSoundChannelDevice"
  
#ifdef __cplusplus
}
#endif

#endif // __XM_BRIDGE_H__