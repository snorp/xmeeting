/*
 * $Id: XMH323EndPoint.cpp,v 1.32 2008/08/14 19:57:05 hfriederich Exp $
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
};

//OPAL_REGISTER_H224_CAPABILITY();

XMH323EndPoint::XMH323EndPoint(OpalManager & manager)
: H323EndPoint(manager)
{
	isListening = false;
	connectionToken = "";
	
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

bool XMH323EndPoint::IsListening()
{
	return isListening;
}

void XMH323EndPoint::SetGatekeeper(const PString & address,
                                   const PString & terminalAlias1,
                                   const PString & terminalAlias2,
                                   const PString & password)
{
  // Use a gatekeeper if terminalAlias1 is not empty
  if (!terminalAlias1.IsEmpty()) {
    // Change the gatekeeper if the address differs
    if (gatekeeper != NULL && address.Compare(gatekeeperAddress) != PObject::EqualTo) {
      RemoveGatekeeper();
      _XMHandleGatekeeperUnregistration();
    }
    
    gatekeeperAddress = address;
    
    //PMutex & mutex = GetAliasNamesMutex();
    //mutex.Wait();
    
    SetLocalUserName(terminalAlias1);
    if (!terminalAlias2.IsEmpty()) {
      AddAliasName(terminalAlias2);
    }
    
    if (!password.IsEmpty()) {
      // This should automatically trigger an URQ/RRQ sequence
      SetGatekeeperPassword(password, terminalAlias1);
    } else if (gatekeeper != NULL) {
      // Do a full RRQ with the updated terminal aliases
     // gatekeeper->OnTerminalAliasChanged();
    }
    
    //mutex.Signal();
    
    if (gatekeeper == NULL) {
      bool result = UseGatekeeper(address);
      if (result == false) {
        if (gatekeeper == NULL) {
          // GRQ failed
          _XMHandleGatekeeperRegistrationFailure(XMGatekeeperRegistrationFailReason_GatekeeperNotFound);
        }
      } else if (result == true && gatekeeper != NULL) {
        // When the initial OnRegistrationConfirm() is called, gatekeeper is still NULL.
        // Handle the RCF here
        HandleRegistrationConfirm();
      }
    }
  } else {
    // Not using a gatekeeper
    if (gatekeeper != NULL) {
      RemoveGatekeeper();
      _XMHandleGatekeeperUnregistration();
    }
    SetLocalUserName(GetManager().GetDefaultUserName());
  }
}

void XMH323EndPoint::HandleRegistrationConfirm()
{
  if (gatekeeper != NULL) {
    PString gatekeeperName = gatekeeper->GetName();
    PStringList aliases = GetAliasNames();
    PStringStream aliasStream;
    for (PINDEX i = 0; i < aliases.GetSize(); i++) {
      if (i != 0) {
        aliasStream << "\n";
      }
      aliasStream << aliases[i];
    }
    _XMHandleGatekeeperRegistration(gatekeeperName, aliasStream);
  }
}

void XMH323EndPoint::HandleNetworkStatusChange()
{
}

#pragma mark Getting call statistics
										
void XMH323EndPoint::GetCallStatistics(XMCallStatisticsRecord *callStatistics)
{
	PSafePtr<H323Connection> connection = FindConnectionWithLock(connectionToken, PSafeReadOnly);
	
	if (connection != NULL)
	{
		unsigned roundTripDelay = connection->GetRoundTripDelay().GetMilliSeconds();
		callStatistics->roundTripDelay = roundTripDelay;
        
    XMOpalManager::ExtractCallStatistics(*connection, callStatistics);
	}
}

#pragma mark Overriding Callbacks

H323Gatekeeper * XMH323EndPoint::CreateGatekeeper(H323Transport * transport)
{
  return new XMH323Gatekeeper(*this, transport);
}

void XMH323EndPoint::OnRegistrationConfirm()
{
	H323EndPoint::OnRegistrationConfirm();  
  HandleRegistrationConfirm();
}

void XMH323EndPoint::OnRegistrationReject()
{
	H323EndPoint::OnRegistrationReject();
}

void XMH323EndPoint::OnEstablished(OpalConnection & connection)
{
	XMOpalManager * manager = (XMOpalManager *)(&GetManager());
	
	connectionToken = connection.GetToken();
    
    const PString & remotePartyName = connection.GetRemotePartyName();
    const PString & remotePartyNumber = connection.GetRemotePartyNumber();
    const PString & remotePartyApplication = connection.GetRemoteApplication();
    
    const H323Transport *signallingChannel = ((H323Connection & )connection).GetSignallingChannel();
    const PString & remotePartyAddress = signallingChannel->GetRemoteAddress().GetHostName();
	
	manager->SetCallInformation(connectionToken,
								remotePartyName,
								remotePartyNumber,
								remotePartyAddress,
								remotePartyApplication,
								XMCallProtocol_H323);
	
	H323EndPoint::OnEstablished(connection);
}

void XMH323EndPoint::OnReleased(OpalConnection & connection)
{
	if (connection.GetToken() == connectionToken)
	{
		XMOpalManager * manager = (XMOpalManager *)(&GetManager());
		PString empty = "";

		manager->SetCallInformation(connectionToken,
									empty,
									empty,
									empty,
									empty,
									XMCallProtocol_H323);
	
		connectionToken = "";
	}
	
	H323EndPoint::OnReleased(connection);
}

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
    
    for (PINDEX i = 0; i < releasingConnections.GetSize(); i++)
    {
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

XMH323Gatekeeper::XMH323Gatekeeper(XMH323EndPoint & ep, H323Transport * transport)
: H323Gatekeeper(ep, transport)
{
}

bool XMH323Gatekeeper::MakeRequest(Request & request)
{
  bool result = H323Gatekeeper::MakeRequest(request);

  if (request.requestPDU.GetPDU().GetTag() == H225_RasMessage::e_registrationRequest) {
    if (result == false) {
      switch(request.responseResult) {
        case Request::AwaitingResponse:
        case Request::NoResponseReceived:
          if (GetRegistrationFailReason() == H323Gatekeeper::UnregisteredByGatekeeper) {
            // GK unregistered client and obviously went offlie afterwards
            _XMHandleGatekeeperRegistrationFailure(XMGatekeeperRegistrationFailReason_UnregisteredByGatekeeper);
          } else {
            _XMHandleGatekeeperRegistrationFailure(XMGatekeeperRegistrationFailReason_GatekeeperNotFound);
          }
          break;
          
        // notify registration failures here as H323EndPoint::OnReceivedRegistrationReject()
        // is called without updated registrationFailReason info
        case Request::RejectReceived:
          switch(request.rejectReason) {
            
            case H225_RegistrationRejectReason::e_invalidCallSignalAddress :
              _XMHandleGatekeeperRegistrationFailure(XMGatekeeperRegistrationFailReason_TransportError);
              break;
              
            case H225_RegistrationRejectReason::e_duplicateAlias :
              _XMHandleGatekeeperRegistrationFailure(XMGatekeeperRegistrationFailReason_DuplicateAlias);
              break;
              
            case H225_RegistrationRejectReason::e_securityDenial :
              _XMHandleGatekeeperRegistrationFailure(XMGatekeeperRegistrationFailReason_SecurityDenied);
              break;
              
            case H225_RegistrationRejectReason::e_discoveryRequired:
            case H225_RegistrationRejectReason::e_fullRegistrationRequired:
              // Do nothing, as we try to re-register ASAP.
              break;
              
            default:
              _XMHandleGatekeeperRegistrationFailure(XMGatekeeperRegistrationFailReason_UnknownFailure);
              break;
          }
          break;
          
        case Request::BadCryptoTokens:
          _XMHandleGatekeeperRegistrationFailure(XMGatekeeperRegistrationFailReason_SecurityDenied);
          break;
          
        default:
          // Do nothing
          break;
      }
    }
  }
  
  return result;
}
