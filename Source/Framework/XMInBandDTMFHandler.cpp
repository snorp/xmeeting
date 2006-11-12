/*
 * $Id: XMInBandDTMFHandler.cpp,v 1.1 2006/11/12 00:19:11 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#include "XMInBandDTMFHandler.h"

XMInBandDTMFHandler::XMInBandDTMFHandler()
: transmitHandler(PCREATE_NOTIFIER(TransmitPacket))
{
	tones = new PDTMFEncoder();
	// pre-allocate used space
	tones->SetSize(8000);
	tones->SetSize(0);
	
	startTimestamp = 0;
	
	PTRACE(3, "InBandDTMF\tHandler created");
}

BOOL XMInBandDTMFHandler::SendTone(char tone, unsigned duration)
{
	PWaitAndSignal m(mutex);
	
	if(tones->GetSize() != 0)
	{
		PTRACE(3, "InBandDTMF\tAlready sending tone");
		return FALSE;
	}
	
	// add the tone
	tones->AddTone(tone, duration);
	tones->SetSize(8*duration); // 8khz sample rate
	
	return TRUE;
}

const PNotifier & XMInBandDTMFHandler::GetTransmitHandler() const
{
	return transmitHandler;
}

void XMInBandDTMFHandler::TransmitPacket(RTP_DataFrame & frame, INT)
{
	if(tones->GetSize() == 0)
	{
		return;
	}
	
	PWaitAndSignal m(mutex);
	
	unsigned actualTimestamp = frame.GetTimestamp();
	if(startTimestamp == 0)
	{
		startTimestamp = actualTimestamp;
	}
	
	unsigned offset = actualTimestamp - startTimestamp;
	unsigned length = frame.GetPayloadSize() / 2;
	unsigned toneLength = tones->GetSize();
	unsigned remainingLength = toneLength - offset;
	if(length > remainingLength)
	{
		length = remainingLength;
	}
	
	short *src = tones->GetPointer();
	src += offset;
	BYTE *dst = frame.GetPayloadPtr();
	
	memcpy(dst, src, 2*length); // 16 bit audio
	
	if(offset + length >= toneLength)
	{
		tones->SetSize(0);
		startTimestamp = 0;
	}
}

