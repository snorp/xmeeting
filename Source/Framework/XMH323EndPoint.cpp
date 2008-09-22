/*
 * $Id: XMH323EndPoint.cpp,v 1.42 2008/09/22 22:56:47 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#include "XMH323EndPoint.h"

#include <ptclib/random.h>
#include <opal/call.h>
#include <h323/h323pdu.h>
#include <h323/gkclient.h>
#include <ptclib/url.h>
#include <ptclib/pils.h>

#include <h224/h323h224.h>
//#include <h323/h46018handler.h>

#include "XMCallbackBridge.h"
#include "XMOpalManager.h"
#include "XMH323Connection.h"

#include <opal/transcoders.h>

#pragma mark Init & Deallocation

class XMH323Gatekeeper : public H323Gatekeeper
{
  PCLASSINFO(XMH323Gatekeeper, H323Gatekeeper);
  
public:
  XMH323Gatekeeper(XMH323EndPoint & endpoint, H323Transport * transport);
  virtual bool MakeRequest(Request & request);
  virtual bool OnReceiveRegistrationConfirm(const H225_RegistrationConfirm &);
  
protected:
  virtual bool DiscoverGatekeeper();
  
private:
  void CheckDoesUseSTUN();
  
  XMH323EndPoint & ep;
  bool doesUseSTUN;
};

class XMH323GkRegistrationThread : public PThread
{
  PCLASSINFO(XMH323GkRegistrationThread, PThread);
  
public:
  XMH323GkRegistrationThread(XMH323EndPoint & ep,
                             const PString & address,
                             const PString & terminalAlias1,
                             const PString & terminalAlias2,
                             const PString & password);
  virtual void Main();
private:
  XMH323EndPoint & ep;
  PString address;
  PString terminalAlias1;
  PString terminalAlias2;
  PString password;
};

//OPAL_REGISTER_H224_CAPABILITY();

XMH323EndPoint::XMH323EndPoint(OpalManager & manager)
: H323EndPoint(manager),
  isListening(false),
  gatekeeperAddress("")
{	
  // Don't use OPAL's bandwidth management system as this is not flexible enough
  // for our purposes
	SetInitialBandwidth(UINT_MAX);
  
  // Use TTL values when doing RRQ. 30s seems appropriate
  SetGatekeeperTimeToLive(PTimeInterval(0, 30));
	
  // Make data streams work. This should be removed in OPAL
	//autoStartReceiveData = autoStartTransmitData = true;
  
  // Manually register H.460 features as the plugin system seems not to work
  //features.AddFeature(new H460_FeatureStd18());
    
  releasingConnections.DisallowDeleteObjects();
}

XMH323EndPoint::~XMH323EndPoint()
{
}

#pragma mark Endpoint Setup

bool XMH323EndPoint::EnableListeners(bool flag)
{
	bool result = true;
	
	if (flag == true) {
		if (isListening == false) {
			result = StartListeners(GetDefaultListeners());
			if (result == true) {
				isListening = true;
			}
		}
	} else {
		if (isListening == true) {
			RemoveListener(NULL);
			isListening = false;
		}
	}
	
	return result;
}

void XMH323EndPoint::SetGatekeeper(const PString & address,
                                   const PString & terminalAlias1,
                                   const PString & terminalAlias2,
                                   const PString & password)
{
  {
    PWaitAndSignal m(GetGatekeeperMutex());
    notifyGkRegistrationComplete = true;
  }

  // Use a gatekeeper only if terminalAlias1 is not empty
  if (!terminalAlias1.IsEmpty()) {
    // Change the gatekeeper if the address differs
    if (gatekeeper != NULL && address.Compare(gatekeeperAddress) != PObject::EqualTo) {
      RemoveGatekeeper();
      _XMHandleGatekeeperUnregistration(); // Don't call the _XMHandleGatekeeperRegistrationComplete() callback
    }
    
    gatekeeperAddress = address;
    
    // update the alias names list
    {
      PWaitAndSignal m(GetGatekeeperMutex());
      SetLocalUserName(terminalAlias1);
      if (!terminalAlias2.IsEmpty()) {
        AddAliasName(terminalAlias2);
      }
    }
    
    if (!password.IsEmpty()) {
      // This should automatically trigger an URQ/RRQ sequence
      SetGatekeeperPassword(password, terminalAlias1);
    } else if (gatekeeper != NULL) {
      // Do a full RRQ with the updated terminal aliases
      gatekeeper->OnTerminalAliasChanged();
    }
    
    if (gatekeeper == NULL) {
      UseGatekeeper(address);
      
      if (gatekeeper == NULL) {
        HandleRegistrationFailure(XMGatekeeperRegistrationStatus_UnknownRegistrationFailure);
      }
    }
  } else {
    // Not using a gatekeeper
    if (gatekeeper != NULL) {
      RemoveGatekeeper();
      HandleUnregistration();
    } else {
      // avoid deadlock
      _XMHandleGatekeeperRegistrationComplete();
    }
    PWaitAndSignal m(GetGatekeeperMutex());
    SetLocalUserName(GetManager().GetDefaultUserName());
  }
}

void XMH323EndPoint::HandleRegistrationConfirm()
{
  PWaitAndSignal m(GetGatekeeperMutex());
  
  if (gatekeeper != NULL) { // should not happen
    PString gatekeeperName = gatekeeper->GetName();
    PStringList aliases = GetAliasNames();
    PStringStream aliasStream;
    for (unsigned i = 0; i < aliases.GetSize(); i++) {
      if (i != 0) {
        aliasStream << "\n";
      }
      aliasStream << aliases[i];
    }
    _XMHandleGatekeeperRegistration(gatekeeperName, aliasStream);
  }
  if (notifyGkRegistrationComplete) {
    _XMHandleGatekeeperRegistrationComplete();
    notifyGkRegistrationComplete = false;
  }
}

void XMH323EndPoint::HandleRegistrationFailure(XMGatekeeperRegistrationStatus status)
{
  PWaitAndSignal m(GetGatekeeperMutex());
  _XMHandleGatekeeperRegistrationFailure(status);
  if (notifyGkRegistrationComplete) {
    _XMHandleGatekeeperRegistrationComplete();
    notifyGkRegistrationComplete = false;
  }
}

void XMH323EndPoint::HandleUnregistration()
{
  PWaitAndSignal m(GetGatekeeperMutex());
  _XMHandleGatekeeperUnregistration();
  if (notifyGkRegistrationComplete) {
    _XMHandleGatekeeperRegistrationComplete();
    notifyGkRegistrationComplete = false;
  }
}

H323Gatekeeper * XMH323EndPoint::CreateGatekeeper(H323Transport * transport)
{
  return new XMH323Gatekeeper(*this, transport);
}

void XMH323EndPoint::OnRegistrationConfirm()
{
	H323EndPoint::OnRegistrationConfirm();  
  HandleRegistrationConfirm();
}

#pragma mark Overriding Callbacks

H323Connection * XMH323EndPoint::CreateConnection(OpalCall & call,
                                                  const PString & token,
                                                  void * userData,
                                                  OpalTransport & transport,
                                                  const PString & alias,
                                                  const H323TransportAddress & address,
                                                  H323SignalPDU * setupPDU,
                                                  unsigned options,
                                                  OpalConnection::StringOptions * stringOptions)
{
  return new XMH323Connection(call, *this, token, alias, address, options, stringOptions);
}

#pragma mark -
#pragma mark H.460 support

bool XMH323EndPoint::OnSendFeatureSet(unsigned id, H225_FeatureSet & message)
{
	return features.SendFeature(id, message);
}

void XMH323EndPoint::OnReceiveFeatureSet(unsigned id, const H225_FeatureSet & message)
{
	features.ReceiveFeature(id, message);
}

#pragma mark -
#pragma mark Clean Up

void XMH323EndPoint::CleanUp() 
{
  PWaitAndSignal m(releasingConnectionsMutex);
  for (unsigned i = 0; i < releasingConnections.GetSize(); i++) {
    releasingConnections[i].CleanUp();
  }
}

void XMH323EndPoint::AddReleasingConnection(XMH323Connection * connection)
{
  PWaitAndSignal m(releasingConnectionsMutex);
  releasingConnections.Append(connection);
}

void XMH323EndPoint::RemoveReleasingConnection(XMH323Connection * connection)
{
  PWaitAndSignal m(releasingConnectionsMutex);
  releasingConnections.Remove(connection);
}

#pragma mark -
#pragma mark XMH323Gatekeeper methods

XMH323Gatekeeper::XMH323Gatekeeper(XMH323EndPoint & theEp, H323Transport * transport)
: H323Gatekeeper(theEp, transport),
  ep(theEp)
{
  CheckDoesUseSTUN();
}

bool XMH323Gatekeeper::DiscoverGatekeeper()
{
  if (!doesUseSTUN) {
    CheckDoesUseSTUN();
    if (doesUseSTUN) {
      // previously, STUN couldn't be used, but now it seems to work
      // all existing UDP sockets of the transport aren't PSTUNUDPSockets.
      // recreate the underlying transport to get working STUN udp sockets
      OpalTransportAddress remoteAddress = transport->GetRemoteAddress();
      delete transport;
      transport = new H323TransportUDP(ep);
      if (!transport->ConnectTo(remoteAddress)) {
        return false;
      }
      if (!StartChannel()) {
        return false;
      }
    }
  }
  bool result = H323Gatekeeper::DiscoverGatekeeper();
  
  if (!result) {
    if (GetRegistrationFailReason() == H323Gatekeeper::UnregisteredByGatekeeper) {
      ep.HandleRegistrationFailure(XMGatekeeperRegistrationStatus_UnregisteredByGatekeeper);
    } else {
      ep.HandleRegistrationFailure(XMGatekeeperRegistrationStatus_GatekeeperNotFound);
    }
  }
  
  return result;
}

bool XMH323Gatekeeper::MakeRequest(Request & request)
{
  bool result = H323Gatekeeper::MakeRequest(request);

  if (request.requestPDU.GetPDU().GetTag() == H225_RasMessage::e_registrationRequest) {
    if (result == false) {
      H225_RasMessage & message = (H225_RasMessage &)request.requestPDU.GetChoice();
      H225_RegistrationRequest & rrq = message;
      
      switch(request.responseResult) {
        case Request::AwaitingResponse:
        case Request::NoResponseReceived:
          if (GetRegistrationFailReason() == H323Gatekeeper::UnregisteredByGatekeeper) {
            // GK unregistered client and obviously went offline afterwards
            ep.HandleRegistrationFailure(XMGatekeeperRegistrationStatus_UnregisteredByGatekeeper);
          } else if (rrq.m_discoveryComplete == true && rrq.HasOptionalField(H225_RegistrationRequest::e_keepAlive) && rrq.m_keepAlive == true) {
            // special handling upon interface changes:
            // Some gatekeepers (e.g. GnuGK) reject the registration request if a keep-alive RRQ arrives from a different interface. Nothing has to be done.
            // Some other gatekeepers don't understand the new rasAddress and send the RCF to the old rasAddress -> this condition here.
            // Workaround: Do a full re-register
            reregisterNow = true;
            monitorTickle.Signal();
          } else {
            ep.HandleRegistrationFailure(XMGatekeeperRegistrationStatus_GatekeeperNotFound);
          }
          break;
          
        // notify registration failures here as H323EndPoint::OnRegistrationReject()
        // is called without updated registrationFailReason info
        case Request::RejectReceived:
          switch(request.rejectReason) {
            
            case H225_RegistrationRejectReason::e_invalidCallSignalAddress :
              ep.HandleRegistrationFailure(XMGatekeeperRegistrationStatus_TransportError);
              break;
              
            case H225_RegistrationRejectReason::e_duplicateAlias :
              ep.HandleRegistrationFailure(XMGatekeeperRegistrationStatus_DuplicateAlias);
              break;
              
            case H225_RegistrationRejectReason::e_securityDenial :
              ep.HandleRegistrationFailure(XMGatekeeperRegistrationStatus_SecurityDenial);
              break;
              
            case H225_RegistrationRejectReason::e_discoveryRequired:
            case H225_RegistrationRejectReason::e_fullRegistrationRequired:
              // Do nothing, as we try to re-register ASAP.
              break;
              
            default:
              ep.HandleRegistrationFailure(XMGatekeeperRegistrationStatus_UnknownRegistrationFailure);
              break;
          }
          break;
          
        case Request::BadCryptoTokens:
          ep.HandleRegistrationFailure(XMGatekeeperRegistrationStatus_SecurityDenial);
          break;
          
        default:
          // Do nothing
          break;
      }
    }
  }
  
  return result;
}

bool XMH323Gatekeeper::OnReceiveRegistrationConfirm(const H225_RegistrationConfirm & confirm) {
  // possible race condition since RCF may cause additional aliases to be added
  PWaitAndSignal m(ep.GetGatekeeperMutex());
  return H323Gatekeeper::OnReceiveRegistrationConfirm(confirm);
}

void XMH323Gatekeeper::CheckDoesUseSTUN()
{
  PSTUNClient *stunClient = ep.GetManager().GetSTUNClient();
  PSTUNClient::NatTypes natType = stunClient->GetNatType();
  
  switch(natType) {
    case PSTUNClient::UnknownNat :
    case PSTUNClient::SymmetricFirewall :
    case PSTUNClient::PortRestrictedNat :
    case PSTUNClient::SymmetricNat : // not sure if this is really needed
      doesUseSTUN = false;
      return;
    default:
      doesUseSTUN = true;
  }
}
