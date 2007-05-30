/*
 * $Id: XMSIPEndPoint.cpp,v 1.32 2007/05/30 08:41:17 hfriederich Exp $
 *
 * Copyright (c) 2006-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2007 Hannes Friederich. All rights reserved.
 */

#include "XMSIPEndPoint.h"

#include "XMCallbackBridge.h"
#include "XMOpalManager.h"
#include "XMSIPConnection.h"
#include "XMMediaFormats.h"
#include "XMNetworkConfiguration.h"

#include <ptlib/ipsock.h>
#include <ptclib/enum.h>

XMSIPEndPoint::XMSIPEndPoint(OpalManager & manager)
: SIPEndPoint(manager)
{
	isListening = FALSE;
	
	connectionToken = "";
	
	SetInitialBandwidth(UINT_MAX);
	
	probingOptions.DisallowDeleteObjects();
	
	SetUserAgent("XMeeting/0.3.4");
	
	SetNATBindingRefreshMethod(EmptyRequest);
    //SetReuseTransports(TRUE);
    
    releasingConnections.DisallowDeleteObjects();
}

XMSIPEndPoint::~XMSIPEndPoint()
{
}

BOOL XMSIPEndPoint::EnableListeners(BOOL enable)
{
	BOOL result = TRUE;
	
	if(enable == TRUE)
	{
		if(isListening == FALSE)
		{
			result = StartListeners(GetDefaultListeners());
			if(result == TRUE)
			{
				isListening = TRUE;
			}
		}
	}
	else
	{
		if(isListening == TRUE)
		{
			RemoveListener(NULL);
			isListening = FALSE;
		}
	}
	
	return result;
}

BOOL XMSIPEndPoint::IsListening()
{
	return isListening;
}

void XMSIPEndPoint::PrepareRegistrationSetup()
{
	PWaitAndSignal m(registrationListMutex);
	
	unsigned i;
	unsigned count = activeRegistrations.GetSize();
	
	// marking all registrations as to unregister/remove
	// If a registration is still used, the status will be overridden again
	for(i = 0; i < count; i++)
	{
		XMSIPRegistrationRecord & record = activeRegistrations[i];
		
		if(record.GetStatus() == XMSIPRegistrationRecord::Registered)
		{
			record.SetStatus(XMSIPRegistrationRecord::ToUnregister);
		}
		else
		{
			record.SetStatus(XMSIPRegistrationRecord::ToRemove);
		}
	}
}

void XMSIPEndPoint::UseRegistration(const PString & host,
                                    const PString & username,
                                    const PString & authorizationUsername,
                                    const PString & password)
{
	PWaitAndSignal m(registrationListMutex);
	
	unsigned i;
	unsigned count = activeRegistrations.GetSize();
	
    PString registration;
	
	PINDEX atLocation = username.Find('@');
	if(atLocation != P_MAX_INDEX)
	{
		registration = username;
	}
	else
	{
        registration = username + '@' + host;
	}
	
	// searching for a record with the same information
	// if found, marking this record as registered/needs to register.
	// if not, create a new record and add it to the list
	for(i = 0; i < count; i++)
	{
		XMSIPRegistrationRecord & record = activeRegistrations[i];
		
		if(record.GetRegistration() == registration)
		{
			if(record.GetPassword() != password)
			{
				record.SetPassword(password);
				record.SetStatus(XMSIPRegistrationRecord::ToRegister);
			}
			else if(record.GetStatus() == XMSIPRegistrationRecord::ToUnregister)
			{
				record.SetStatus(XMSIPRegistrationRecord::Registered);
			}
			else
			{
				record.SetStatus(XMSIPRegistrationRecord::ToRegister);
			}
			
			return;
		}
	}
	
	XMSIPRegistrationRecord *record = new XMSIPRegistrationRecord(registration, authorizationUsername, password);
	record->SetStatus(XMSIPRegistrationRecord::ToRegister);
	activeRegistrations.Append(record);
}

void XMSIPEndPoint::FinishRegistrationSetup()
{
	PWaitAndSignal m(registrationListMutex);
	
	int i;
	unsigned count = activeRegistrations.GetSize();
	
	for(i = (count-1); i >= 0; i--)
	{
		XMSIPRegistrationRecord & record = activeRegistrations[i];
		
		if(record.GetStatus() == XMSIPRegistrationRecord::ToUnregister)
		{
			Unregister(record.GetRegistration());
			
			_XMHandleSIPUnregistration(record.GetRegistration());
			
			activeRegistrations.RemoveAt(i);
		}
		else if(record.GetStatus() == XMSIPRegistrationRecord::ToRemove)
		{
			activeRegistrations.RemoveAt(i);
		}
		else if(record.GetStatus() == XMSIPRegistrationRecord::ToRegister)
		{
            BOOL result = Register(GetRegistrarTimeToLive().GetSeconds(),
                                   record.GetRegistration(),
                                   record.GetAuthorizationUsername(),
                                   record.GetPassword());
            
			if(result == FALSE && (record.GetStatus() != XMSIPRegistrationRecord::Failed))
			{
				record.SetStatus(XMSIPRegistrationRecord::Failed);
				
				_XMHandleSIPRegistrationFailure(record.GetRegistration(), XMSIPStatusCode_UnknownFailure);
			}
		}
	}
	
	BOOL completed = TRUE;
	count = activeRegistrations.GetSize();
	for(i = 0; i < count; i++)
	{
		XMSIPRegistrationRecord & record = activeRegistrations[i];
		
		if(record.GetStatus() == XMSIPRegistrationRecord::ToRegister)
		{
			completed = FALSE;
			break;
		}
	}
	
	if(completed == TRUE)
	{
		_XMHandleSIPRegistrationSetupCompleted();
	}
}

void XMSIPEndPoint::HandleNetworkStatusChange()
{
}

void XMSIPEndPoint::UseProxy(const PString & hostname,
							 const PString & username,
							 const PString & password)
{
	PString adjustedUsername;
	
	PINDEX location = username.Find('@');
	if(location != P_MAX_INDEX)
	{
		adjustedUsername = username.Left(location);
	}
	else
	{
		adjustedUsername = username;
	}
	
	SetProxy(hostname, username, password);
}

void XMSIPEndPoint::GetCallStatistics(XMCallStatisticsRecord *callStatistics)
{
	PSafePtr<SIPConnection> connection = GetSIPConnectionWithLock(connectionToken, PSafeReadOnly);
	
	if(connection != NULL)
	{
		// not supported at the moment
		callStatistics->roundTripDelay = UINT_MAX;
		
        XMOpalManager::ExtractCallStatistics(*connection, callStatistics);
	}
}

void XMSIPEndPoint::OnRegistrationFailed(const PString & aor,
										 SIP_PDU::StatusCodes reason,
										 BOOL wasRegistering)
{
	if(wasRegistering == FALSE)
	{
		return;
	}
	
	PWaitAndSignal m(registrationListMutex);
	
	BOOL setupIsComplete = TRUE;
	
	unsigned i;
	unsigned count = activeRegistrations.GetSize();
	
	for(i = 0; i < count; i++)
	{
		XMSIPRegistrationRecord & record = activeRegistrations[i];
		
		if(aor == record.GetRegistration())
		{
			if(record.GetStatus() != XMSIPRegistrationRecord::ToRegister)
			{
				return;
			}
			record.SetStatus(XMSIPRegistrationRecord::Failed);
			
			_XMHandleSIPRegistrationFailure(record.GetRegistration(), (XMSIPStatusCode)reason);
		}
		
		unsigned status = record.GetStatus();
		
		if(status == XMSIPRegistrationRecord::ToRegister)
		{
			setupIsComplete = FALSE;
		}
	}
	
	if(setupIsComplete == TRUE)
	{
		_XMHandleSIPRegistrationSetupCompleted();
		return;
	}
}

void XMSIPEndPoint::OnRegistered(const PString & aor,
								 BOOL wasRegistering)
{
	if(wasRegistering == FALSE)
	{
		return;
	}
	
	PWaitAndSignal m(registrationListMutex);
    
	
	BOOL setupIsComplete = TRUE;
	
	unsigned i;
	unsigned count = activeRegistrations.GetSize();
	
	for(i = 0; i < count; i++)
	{
		XMSIPRegistrationRecord & record = activeRegistrations[i];
		
		if(aor == record.GetRegistration())
		{
			unsigned status = record.GetStatus();
			
			if(status == XMSIPRegistrationRecord::ToRegister)
			{
				_XMHandleSIPRegistration(record.GetRegistration());
			}
			
			record.SetStatus(XMSIPRegistrationRecord::Registered);
			
			if(status != XMSIPRegistrationRecord::ToRegister)
			{
				return;
			}
		}
		
		if(record.GetStatus() == XMSIPRegistrationRecord::ToRegister)
		{
			setupIsComplete = FALSE;
		}
	}
	
	if(setupIsComplete == TRUE)
	{
		_XMHandleSIPRegistrationSetupCompleted();
	}
}

void XMSIPEndPoint::OnEstablished(OpalConnection & connection)
{
	XMOpalManager *manager = (XMOpalManager *)(&GetManager());
	
	connectionToken = connection.GetToken();
    
    SIPURL remoteURL = SIPURL(connection.GetRemotePartyAddress());
    const PString & username = remoteURL.GetUserName();
    const PString & host = remoteURL.GetHostName();
    PString remoteAddress;
    
    if (username != "") {
        remoteAddress = username + "@" + host;
    } else {
        remoteAddress = host;
    }
	
	manager->SetCallInformation(connectionToken,
								connection.GetRemotePartyName(),
								"",
								remoteAddress,
								connection.GetRemoteApplication(),
								XMCallProtocol_SIP);
	
	SIPEndPoint::OnEstablished(connection);
}

void XMSIPEndPoint::OnReleased(OpalConnection & connection)
{
	if(connection.GetToken() == connectionToken)
	{
		XMOpalManager *manager = (XMOpalManager *)(&GetManager());
		PString empty = "";
	
		manager->SetCallInformation(connectionToken,
									empty,
									empty,
									empty,
									empty,
									XMCallProtocol_SIP);
	
		connectionToken = "";
	}
	
	SIPEndPoint::OnReleased(connection);
}

SIPConnection * XMSIPEndPoint::CreateConnection(OpalCall & call,
												const PString & token,
												void * userData,
												const SIPURL & destination,
												OpalTransport * transport,
												SIP_PDU * invite,
												unsigned int options,
                                                OpalConnection::StringOptions * stringOptions)
{
	return new XMSIPConnection(call, *this, token, destination, transport, options, stringOptions);
}

BOOL XMSIPEndPoint::AdjustInterfaceTable(PIPSocket::Address & remoteAddress,
										 PIPSocket::InterfaceTable & interfaceTable)
{
	for(int i = interfaceTable.GetSize()-1; i >= 0; i--) {
		PIPSocket::InterfaceEntry & interface = interfaceTable[i];
		
		PIPSocket::Address localAddress = interface.GetAddress();
		
		// Remove loopback interface
		if(localAddress.IsLoopback()) {
			interfaceTable.RemoveAt(i);
			continue;
		}
		
		// remove non-RFC1918 interface if destination is RFC1918
		if(remoteAddress.IsRFC1918() && !localAddress.IsRFC1918()) {
			interfaceTable.RemoveAt(i);
			continue;
		}
		
		in_addr localAddr = interface.GetAddress();
		in_addr remoteAddr = remoteAddress;
		
		int result = XMGetReachabilityStatusForAddresses(&localAddr, &remoteAddr);
		if(result == XM_NOT_REACHABLE) {
			interfaceTable.RemoveAt(i);
		} else if(result == XM_DIRECT_REACHABLE) {
			interfaceTable.DisallowDeleteObjects();
			interfaceTable.RemoveAt(i);
			interfaceTable.AllowDeleteObjects();
			interfaceTable.RemoveAll();
			interfaceTable.Append(&interface);
			break;
		}
	}
	return TRUE;
}

/*SIPRegisterInfo * XMSIPEndPoint::CreateRegisterInfo(const PString & originalHost,
									  			    const PString & adjustedUsername, 
												    const PString & authName, 
												    const PString & password, 
												    int timeout, 
												    const PTimeInterval & minRetryTime, 
												    const PTimeInterval & maxRetryTime)
{
	return new XMSIPRegisterInfo(*this, originalHost, adjustedUsername, authName, password, timeout, minRetryTime, maxRetryTime);
}*/

/**
 * Creates a transport using the default OPAL facilities. Afterwards,
 * an OPTIONS probing is done on each interface to determine which
 * interface to use for subsequent REGISTER / INVITE operation.
 * This is useful to avoid many potential problems arising when sending
 * multiple INVITE / REGISTER out as these messages cause state changes
 * on the remote side. OPTIONS don't alter state, in contrast.
 **/
/*OpalTransport * XMSIPEndPoint::CreateTransport(const OpalTransportAddress & addr, const OpalTransport * originalTransport)
{
	// create the transport
	OpalTransport *transport = SIPEndPoint::CreateTransport(addr, originalTransport);
	
	// Sanity check
	if(transport == NULL)
	{
		return NULL;
	}
	
	if(!PIsDescendant(transport, OpalTransportUDP)) {
		return transport;
	}
	
	OpalTransportUDP * udpTransport = (OpalTransportUDP *)transport;
	if(udpTransport->NumberOfConnectSockets() <= 1)
	{
		return transport; // Don't do OPTIONS probing if there is only one transport
	}
	
	PWaitAndSignal m(transportMutex); // Serializes the OPTIONS probing procedure to decrease resources used
	
	// Extract the host from the transport address. Unfortunately,
	// there is no direct way to do this.
	PINDEX start = addr.Find('$') + 1;
	PINDEX end = addr.Find(':');
	PString host = addr.Mid(start, (end-start));
	
	// Create a SIP OPTIONS transaction which is used to probe the interfaces
	SIPURL url = SIPURL(host);
	
	// simple double-pointer to pass endpoint / url information to the
	// WriteSIPOptions callback
	void* data[2];
	data[0] = (void *)this;
	data[1] = (void *)&url;
	
	probingOptionsMutex.Wait(); // protect against race conditions
	probingSuccessful = TRUE;
	BOOL result = transport->WriteConnect(WriteSIPOptions, data);
	probingOptionsMutex.Signal();
	if(result == FALSE)
	{
		// something failed
		delete transport;
		return NULL;
	}
	
	probingSyncPoint.Wait(); // wait until  probing completed
	
	return transport;
}*/

/*
 * Callback that gets called for each available interface to write out
 * an OPTIONS probing request
 */
/*BOOL XMSIPEndPoint::WriteSIPOptions(OpalTransport & transport, void *data)
{
	void **theData = (void **)data;
	XMSIPEndPoint *endPoint = (XMSIPEndPoint *)(theData[0]);
	SIPURL *url = (SIPURL *)(theData[1]);
	
	XMSIPOptions *options = new XMSIPOptions(*endPoint, transport, *url);
	if(!options->Start()) {
		delete options;
		return FALSE;
	}
	
	endPoint->probingOptions.SetAt(options->GetTransactionID(), options);
	
	return TRUE;
}*/

/*
 * Gets called every time a response is received.
 * Filters out OPTIONS responses and processes them separately
 */
/*void XMSIPEndPoint::OnReceivedResponse(SIPTransaction & transaction, SIP_PDU & response)
{
	if(transaction.GetMethod() == SIP_PDU::Method_OPTIONS)
	{
	    // A response from an OPTIONS probing request was received.
		probingOptionsMutex.Wait();
		if(probingOptions.Contains(transaction.GetTransactionID()))
		{ 
			// ensures that only transactions belonging to this group are processsed
			// In addition, ensure that the sync point gets signaled only once
			OpalTransport & transport = transaction.GetTransport();
			transport.EndConnect(transaction.GetLocalAddress());
			probingOptions.RemoveAll();
			probingSyncPoint.Signal();
		}
		probingOptionsMutex.Signal();
		return;
	}
	SIPEndPoint::OnReceivedResponse(transaction, response);
}*/

/*
 * Gets called by XMSIPOptions instances when their transaction
 * times out. Needed to ensure that the OPTIONS probing fails
 * after all OPTIONS transactions have timed out.
 */
/*void XMSIPEndPoint::OnOptionsTimeout(XMSIPOptions *options)
{
	probingOptionsMutex.Wait();
	if(probingOptions.Contains(options->GetTransactionID()))
	{
		// Remove this transaction from the options dictionary.
		// If the dictionary is empty after this operation,
		// make probingSuccessful FALSE and signal the sync point
		probingOptions.SetAt(options->GetTransactionID(), NULL);
		
		if(probingOptions.GetSize() == 0)
		{
			probingSuccessful = FALSE;
			probingSyncPoint.Signal();
		}
	}
	probingOptionsMutex.Signal();
}*/

SIPURL XMSIPEndPoint::GetDefaultRegisteredPartyName()
{
	// If using a proxy, use the proxy user name and domain name
	SIPURL proxyURL = GetProxy();
	if(!proxyURL.IsEmpty())
	{
		return proxyURL;
	}
	
	// Get the superclass's implementation
	SIPURL url = SIPEndPoint::GetDefaultRegisteredPartyName();

	// If the superclass returns IP "0.0.0.0", make the
	// OpalTransportAddress empty. This in turn indicates
	// to the callers that they should use the current
	// transport's local address
	OpalTransportAddress address = url.GetHostAddress();
	PIPSocket::Address ip;
	if(!address.GetIpAddress(ip))
	{
		return url;
	}
	if(ip.IsAny())
	{
		url = SIPURL(GetDefaultLocalPartyName(), OpalTransportAddress());
	}
	return url;
}

void XMSIPEndPoint::CleanUp()
{
    // Clean up all connections
    {
        PWaitAndSignal m(releasingConnectionsMutex);
        for (PINDEX i = 0; i < releasingConnections.GetSize(); i++)
        {
            releasingConnections[i].CleanUp();
        }
    }
}

void XMSIPEndPoint::AddReleasingConnection(XMSIPConnection * connection)
{
    PWaitAndSignal m(releasingConnectionsMutex);
    
    releasingConnections.Append(connection);
}

void XMSIPEndPoint::RemoveReleasingConnection(XMSIPConnection * connection)
{
    PWaitAndSignal m(releasingConnectionsMutex);
    
    releasingConnections.Remove(connection);
}

#pragma mark -
#pragma mark XMSIPRegistrationRecord methods

XMSIPRegistrationRecord::XMSIPRegistrationRecord(const PString & _registration,
                                                 const PString & _authorizationUsername,
                                                 const PString & _password)
{
	registration = _registration;
	authorizationUsername = _authorizationUsername;
	password = _password;
}

XMSIPRegistrationRecord::~XMSIPRegistrationRecord()
{
}

#pragma mark -
#pragma mark XMSIPRegisterInfo methods

/*XMSIPRegisterInfo::XMSIPRegisterInfo(XMSIPEndPoint & ep, 
									 const PString & originalHost,
									 const PString & adjustedUsername, 
									 const PString & authName, 
									 const PString & password, 
									 int expire,
									 const PTimeInterval & minRetryTime,
									 const PTimeInterval & maxRetryTime)
: SIPRegisterInfo(ep, originalHost, adjustedUsername, authName, password, expire, minRetryTime, maxRetryTime)
{
}

XMSIPRegisterInfo::~XMSIPRegisterInfo()
{
}

BOOL XMSIPRegisterInfo::CreateTransport(OpalTransportAddress & addr)
{
	transportMutex.Wait();
	
	registrarAddress = addr;
	
	if(registrarTransport == NULL)
	{
		// Since the XMCreateTransport method may take some time until it completes,
		// and since this might involve timeouts, there is a race condition between
		// this operation and the NAT binding refresh operation, which locks the
		// transportMutex as well. Therefore, it is required to release the mutex lock
		// in between.
		transportMutex.Signal();
		OpalTransport *transport;
		transport = ep.CreateTransport(registrarAddress);
		transportMutex.Wait();
		if(registrarTransport != NULL) {
			delete transport;
		} else {
			registrarTransport = transport;
		}
	}
	
	if(registrarTransport == NULL)
	{
		OnFailed(SIP_PDU::Failure_BadGateway);
		transportMutex.Signal();
		return FALSE;
	}
	
	transportMutex.Signal();
	return TRUE;
}*/

/*BOOL XMSIPRegisterInfo::WillExpireWithinTimeInterval(PTimeInterval interval)
{	
	if(registered == FALSE)
	{
		return FALSE;
	}
	
	PTime currentTime = PTime();
	
	if((currentTime - registrationTime) >= PTimeInterval(0, expire))
	{
		// already expired
		return FALSE;
	}
	PTimeInterval adjustedExpire = PTimeInterval(0, expire - interval.GetSeconds());
	if((currentTime - registrationTime) >= adjustedExpire)
	{
		return TRUE;
	}
	
	return FALSE;
}*/

#pragma mark -
#pragma mark XMSIPOptions methods

/*XMSIPOptions::XMSIPOptions(SIPEndPoint & ep, OpalTransport & trans, const SIPURL & address)
: SIPTransaction(ep, trans)
{
	OpalTransportAddress transportAddress = trans.GetLocalAddress();
	PIPSocket::Address addr;
	WORD port;
	transportAddress.GetIpAndPort(addr, port);
	PString requestURI;
	PString hosturl;
	PString id = OpalGloballyUniqueID().AsString() + "@" + PIPSocket::GetHostName();
	OpalTransportAddress viaAddress = ep.GetLocalURL(transport).GetHostAddress();
	
	// Build the From field
	PString displayName = ep.GetDefaultDisplayName();
	SIPURL registeredPartyAddress = ep.GetRegisteredPartyName(address.GetHostName());
	PString localName = registeredPartyAddress.GetUserName();
	PString domain = registeredPartyAddress.GetHostName();
	
	// if no domain, use the local domain as default
	if(domain.IsEmpty()) {
		domain = addr.AsString();
		if(port != endpoint.GetDefaultSignalPort())
		{
			domain += psprintf(":%d", port);
		}
	}
	if(localName.IsEmpty())
	{
		localName = ep.GetDefaultLocalPartyName();
	}
	
	SIPURL myAddress("\"" + displayName + "\" <" + localName + "@" + domain + ">");
	
	requestURI = "sip:" + address.AsQuotedString();
	
	SIP_PDU::Construct(Method_OPTIONS,
					   requestURI,
					   address.AsQuotedString(),
					   myAddress.AsQuotedString() + ";tag=" + OpalGloballyUniqueID().AsString(),
					   id,
					   endpoint.GetNextCSeq(),
					   viaAddress);
	mime.SetAccept("application/sdp");
	
}

XMSIPOptions::~XMSIPOptions()
{
}

BOOL XMSIPOptions::Start()
{
	BOOL result = SIPTransaction::Start();
	if(result == TRUE)
	{
		// override the default timeot to avoid two complete timeouts passing when trying
		// to REGISTER and the remote host doesn't answer
		completionTimer = PTimeInterval(0, 5);
	}
	return result;
}

void XMSIPOptions::OnTimeout(PTimer & timer, INT value)
{
	SIPTransaction::OnTimeout(timer, value);
	XMSIPEndPoint & xmEP = (XMSIPEndPoint &)endpoint;
	xmEP.OnOptionsTimeout(this);
	delete this;
}

void XMSIPOptions::SetTerminated(States newState)
{
	SIPTransaction::SetTerminated(newState);
	if(newState == Terminated_TransportError)
	{
		// This occurs when the retransmission timeout
		// occurs but the underlying OpalTransport is not
		// writable for the desired interface anymore.
		// -> EndConnect() has already been called.
		//
		// Still set a timer that deletes this instance
		// after a short timeout
		completionTimer = PTimeInterval(0, 4); // delete after 4s
	}
}*/
		