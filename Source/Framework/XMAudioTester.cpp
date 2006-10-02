/*
 * $Id: XMAudioTester.cpp,v 1.2 2006/10/02 21:22:03 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Andreas Fenkart, Hannes Friederich. All rights reserved.
 */

#include "XMBridge.h"
#include "XMCallbackBridge.h"
#include "XMAudioTester.h"

static XMAudioTester *audioTester = NULL;
static PMutex audioTesterMutex;

XMAudioTester::XMAudioTester(unsigned theDelay)
: PThread(4096,
		  NoAutoDeleteThread,
		  HighestPriority,
		  "Audio Test Thread:%x"),
circularBuffer((theDelay*8000*2)+320)
{
	delay = theDelay;
}

void XMAudioTester::Main()
{
	PSoundChannel *inputChannel = new PSoundChannel();
	PSoundChannel *outputChannel = new PSoundChannel();
	
	if(!inputChannel->Open(XMInputSoundChannelDevice, PSoundChannel::Recorder, 1, 8000, 16) ||
	   !inputChannel->SetBuffers(320, 2) ||
	   !inputChannel->StartRecording())
	{
		inputChannel->Close();
		delete inputChannel;
		delete outputChannel;
		return;
	}
	if(!outputChannel->Open(XMSoundChannelDevice, PSoundChannel::Player, 1, 8000, 16) ||
	   !outputChannel->SetBuffers(320, 2))
	{
		inputChannel->Close();
		outputChannel->Close();
		delete inputChannel;
		delete outputChannel;
		return;
	}
	
	// The code in its current form does a lot of avoidable buffer copy operations.
	// However, the overall CPU load is still a lot smaller than when in a real
	// conference. It's definitively not worth optimizing for speed here.
	BYTE data[320];
	unsigned counter = 0;
	int numberOfReads = 50*delay;
	
	while(TRUE)
	{
		if(stop == TRUE)
		{
			break;
		}
		inputChannel->Read(data, 320);
		circularBuffer.Fill((char *)data, 320, false, true);
		counter++;
		
		if(counter >= numberOfReads)
		{
			circularBuffer.Drain((char *)data, 320, false);
			outputChannel->Write((char *)data, 320);
		}
	}
	
	inputChannel->Close();
	outputChannel->Close();
	delete inputChannel;
	delete outputChannel;
}

void XMAudioTester::Start(unsigned delay)
{
	PWaitAndSignal m(audioTesterMutex);
	
	if(audioTester == NULL)
	{
		audioTester = new XMAudioTester(delay);
		audioTester->stop = FALSE;
		audioTester->Restart();
	}
}

void XMAudioTester::Stop()
{
	PWaitAndSignal m(audioTesterMutex);
	
	if(audioTester != NULL)
	{
		audioTester->stop = TRUE;
		audioTester->WaitForTermination();
		delete audioTester;
		audioTester = NULL;
		_XMHandleAudioTestEnd();
	}
}

