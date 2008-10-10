/*
 * $Id: XMOpalManager.h,v 1.48 2008/10/10 09:00:10 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_OPAL_MANAGER_H__
#define __XM_OPAL_MANAGER_H__

#include <ptlib.h>
#include <opal/manager.h>

#include "XMTypes.h"

#include "XMMediaFormats.h"

class XMEndPoint;
class XMH323EndPoint;
class XMSIPEndPoint;

class XMOpalManager : public OpalManager
{
  PCLASSINFO(XMOpalManager, OpalManager);
	
public:
  static void InitOpal(const PString & pTracePath, bool logCallStatistics);
  static void CloseOpal();
	
  XMOpalManager(bool logCallStatistics);
  ~XMOpalManager();
	
  /* Getting access to the OPAL manager */
  static XMOpalManager * GetManager();
	
  /* Getting access to the endpoints */
  static XMH323EndPoint * GetH323EndPoint();
  static XMSIPEndPoint * GetSIPEndPoint();
  static XMEndPoint * GetCallEndPoint();
  
  /* Handle network configuration changes */
  void HandleNetworkConfigurationChange();
  
  /* NAT methods */
  void SetNATInformation(const PStringArray & stunServers, const PString & publicAddress);
  void HandlePublicAddressUpdate(const PString & publicAddress);
    
  /* Initiating a call */
  void InitiateCall(XMCallProtocol protocol, const char * remoteParty, const char *origAddressString);
  void HandleCallInitiationFailed(XMCallEndReason endReason);
	
  /* getting remote applcation info */
  static PString GetRemoteApplicationString(const OpalProductInfo & info);
	
  /* getting call statistics */
  void GetCallStatistics(const PString & callToken, XMCallStatisticsRecord *callStatistics);
	
  /* overriding some callbacks */
  virtual void OnEstablishedCall(OpalCall & call);
  virtual void OnReleased(OpalConnection & connection);
  virtual OpalMediaPatch * CreateMediaPatch(OpalMediaStream & source, bool requiresPatchThread = true);
    
  void OnOpenRTPMediaStream(const OpalConnection & connection, const OpalMediaStream & stream);
  void OnClosedRTPMediaStream(const OpalConnection & connection, const OpalMediaStream & stream);
	
  /* General setup methods */
  void SetUserName(const PString & name);

  /* Bandwidth usage */
  unsigned GetBandwidthLimit() const { return bandwidthLimit; }
  void SetBandwidthLimit(unsigned limit);
  unsigned GetVideoBandwidthLimit() const { return bandwidthLimit - 64000; }
	
  /* Audio setup methods */
  void SetAudioPacketTime(unsigned _audioPacketTime) { audioPacketTime = _audioPacketTime; }
    
  /* H.264 methods */
  bool GetEnableH264LimitedMode() const { return enableH264LimitedMode; }
  void SetEnableH264LimitedMode(bool _enable) { enableH264LimitedMode = _enable; }
	
  /* User input mode information */
  bool SetUserInputMode(XMUserInputMode userInputMode);
	
  /* Debug log information */
  static void LogMessage(const PString & message);
    
  /* Define current codec bandwidth limits */
  static unsigned GetH261BandwidthLimit();
  static unsigned GetH263BandwidthLimit();
  static unsigned GetH264BandwidthLimit();
  
  virtual void AdjustMediaFormats(const OpalConnection & connection, OpalMediaFormatList & mediaFormats) const;
	
private:
  void UpdateNetworkInterfaces();
  void SetupNATTraversal();
  void HandleSTUNInformation(PSTUNClient::NatTypes natType, const PString & publicAddress);
  bool HasNetworkInterfaces() const;
  void ExtractLocalAddress(const PString & callToken, OpalConnection * connection);
  
  class XMInterfaceMonitor : public OpalManager::InterfaceMonitor
  {
    PCLASSINFO(XMInterfaceMonitor, OpalManager::InterfaceMonitor);
    
    public:
      XMInterfaceMonitor(XMOpalManager & manager);
      void OnAddInterface(const PIPSocket::InterfaceEntry & entry);
      void OnRemoveInterface(const PIPSocket::InterfaceEntry & entry);
    private:
      XMOpalManager & manager;
  };
  
  class XMSTUNClient : public PSTUNClient
  {
    PCLASSINFO(XMSTUNClient, PSTUNClient);
    
    public:
      XMSTUNClient();
      bool GetEnabled() const { return enabled; }
      void SetEnabled(bool _enabled) { enabled = _enabled; } 
    
    private:
      bool enabled;
  };
  
  class XMInterfaceUpdateThread : public PThread
  {
    PCLASSINFO(XMInterfaceUpdateThread, PThread);
    
    public:
      XMInterfaceUpdateThread(XMOpalManager & manager);
      virtual void Main();
    private:
      XMOpalManager & manager;
  };
  
  PStringArray stunServers;
  PString publicAddress;
  XMInterfaceUpdateThread *interfaceUpdateThread;
  PMutex natMutex;
  
  unsigned bandwidthLimit;
  unsigned audioPacketTime;
  
  bool enableH264LimitedMode;
	
  PMutex callMutex;
    
  // used during InitiateCall()
  XMCallEndReason callEndReason;
  
  // tracing of the call statistics
  bool logCallStatistics;
};

#endif // __XM_OPAL_MANAGER_H__
