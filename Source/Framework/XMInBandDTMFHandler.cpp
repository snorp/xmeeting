/*
 * $Id: XMInBandDTMFHandler.cpp,v 1.5 2008/09/24 06:52:42 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#include "XMInBandDTMFHandler.h"

// borrowed from PDTMFEncoder
static unsigned const dtmfFreqs[16][2] = {
  { 941,1336 },  // 0
  { 697,1209 },  // 1
  { 697,1336 },  // 2
  { 697,1477 },  // 3
  { 770,1209 },  // 4
  { 770,1336 },  // 5
  { 770,1477 },  // 6
  { 852,1209 },  // 7
  { 852,1336 },  // 8
  { 852,1477 },  // 9
  { 697,1633 },  // A
  { 770,1633 },  // B
  { 852,1633 },  // C
  { 941,1633 },  // D
  { 941,1209 },  // *
  { 941,1477 }   // #
};

XMInBandDTMFHandler::XMInBandDTMFHandler()
: transmitHandler(PCREATE_NOTIFIER(TransmitPacket))
{
  tones = new PTones();
  // pre-allocate used space
  tones->SetSize(8000);
  tones->SetSize(0);
	
  startTimestamp = 0;
	
  PTRACE(3, "InBandDTMF\tHandler created");
}

bool XMInBandDTMFHandler::SendTone(char tone, unsigned duration)
{
  PWaitAndSignal m(mutex);
	
  if(tones->GetSize() != 0) {
    PTRACE(3, "InBandDTMF\tAlready sending tone");
    return false;
  }
	
  // map the tone digits to the correct indexes
  char digit = (char)toupper(tone);
  PINDEX index;
  if ('0' <= digit && digit <= '9') {
    index = digit - '0';
	} else if ('A' <= digit && digit <= 'D') {
		index = digit + 10 - 'A';
	} else if (digit == '*') {
		index = 14;
	} else if (digit == '#') {
		index = 15;
	} else {
		return false;
	}
	
  // send at least 400 ms tones
	if(duration < 400) {
		duration = 400;
	}
	
  // Generate the tone
  tones->Generate('+', dtmfFreqs[index][0], dtmfFreqs[index][1], duration);
	
  // limit tone duration to desired duration
  tones->SetSize(8*duration); // 8khz sample rate
	
  return true;
}

const PNotifier & XMInBandDTMFHandler::GetTransmitHandler() const
{
  return transmitHandler;
}

void XMInBandDTMFHandler::TransmitPacket(RTP_DataFrame & frame, INT)
{
  if(tones->GetSize() == 0) {
    return;
  }
	
  PWaitAndSignal m(mutex);
	
  unsigned actualTimestamp = frame.GetTimestamp();
  if(startTimestamp == 0) {
    startTimestamp = actualTimestamp;
  }
	
  unsigned offset = actualTimestamp - startTimestamp;
  unsigned length = frame.GetPayloadSize() / 2;
  unsigned toneLength = tones->GetSize();
  unsigned remainingLength = toneLength - offset;
  if(length > remainingLength) {
    length = remainingLength;
  }
	
  short *src = tones->GetPointer();
  src += offset;
  BYTE *dst = frame.GetPayloadPtr();
	
  memcpy(dst, src, 2*length); // 16 bit audio
	
  // stop tone transmission at the end
  if(offset + length >= toneLength) {
    tones->SetSize(0);
    startTimestamp = 0;
	}
}

