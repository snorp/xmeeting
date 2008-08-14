/*
 * $Id: XMCircularBuffer.h,v 1.6 2008/08/14 19:57:05 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Andreas Fenkart, Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CIRCULAR_BUFFER_H__
#define __XM_CIRCULAR_BUFFER_H__

#include <ptlib.h>

/**
 * Simple circular buffer for one producer and consumer with a head and a 
 * tail that chase each other. The capacity is 1 byte bigger than necessary 
 * due to a sentinel, to tell apart full from empty by the following equations:
 *
 * full  := head_next == tail
 * empty := head      == tail
 *
 * Inspired by CircularBuffer from beaudio.
 * We need a lock when updating the tail index, due to the overwrite mechanism
 * in case of buffer overflow. The head index needs no locking because 
 * overwrite does not make sense in case of buffer underrun. 
 *
 * Keep in mind that this buffer does no know about frames or packets, it's up
 * to you to make sure you get the right number of bytes. In doubt use size() 
 * to compute how many frames/packets it is save to drain/fill.
 *
 * This buffer does also offer the chance to *stop* the buffer from being used
 * through calling Stop(). After that, any bytes sent to Fill() will just be
 * ignored and Drain returns a zero-filled buffer. This method also unblocks any
 * thread locked when calling Fill() or Drain(). So, Stop() allows a third party
 * to interfere with the buffer behaviour and to remove any deadlocks.
 * The call to Restart() will undo the operation above and *start* the buffer
 * again. However, the buffer is considered empty after Restart().
 **/

class XMCircularBuffer
{
public:

	explicit XMCircularBuffer(PINDEX len);
	~XMCircularBuffer();
    
	/** 
	 * Fill inserts data into the circular buffer. 
     * Remind that lock and overwrite are mutually exclusive. If you set lock,
     * overwrite will be ignored. Returns the amount of bytes actually
	 * written to the buffer. If lock is true, this function blocks
	 * until all bytes have been written (or the buffer was *stopped*)
     **/
	PINDEX Fill(const char* inbuf, PINDEX len, bool lock = true, 
				bool overwrite = false);


	/** 
	 * See also Fill.
	 * Returns the amount of bytes read from the buffer. If lock is true,
	 * blocks until all bytes have been obtained. If the buffer is stopped,
     * all remaining bytes are set to zero.
     * If maxWaitTime is smaller than UINT_MAX, the buffer will wait at most
     * maxWaitTime milliseconds for data before the buffer enters a "self-filling"
     * state which lasts until the next call to Fill(). In the self-filling
     * state, Drain() always zero-fills the buffer in the desired length.
     * This is to avoid deadlock-like situations if the source thread does not
     * fill the buffer over a longer period.
     **/
	PINDEX Drain(char* outbuf, PINDEX len, bool lock = true, unsigned maxWaitTime = UINT_MAX);
	
	/**
	 * *Starts* / *Stops* the buffer as desired
	 **/
	void Stop();
	void Restart();
    
    /**
     * Returns if the buffer is currently full
     **/
    bool Full();
    
    /**
     * Returns if the buffer is currently empty
     **/
    bool Empty();
    
    /**
     * Returns the number of bytes currently in the buffer
     **/
    PINDEX Size();
    
    /**
     * Sets the data rate (in bytes/s) for this buffer. Needed for the selfFilling state
     **/
    void SetDataRate(unsigned _dataRate) { dataRate = _dataRate; }

 private:
    inline bool full() const;
    inline bool empty() const;
    inline PINDEX size() const;
    inline PINDEX free() const;
    
	inline void increment_head(PINDEX inc);    
	inline void increment_tail(PINDEX inc);
    
    inline int mutex_lock();
    inline int mutex_unlock();
    inline int cond_wait();
    inline int cond_timedwait(unsigned waitTime);
    inline int cond_signal();
    inline int cond_broadcast();
	
    char* buffer;
    const PINDEX capacity;
    volatile PINDEX head;
    volatile PINDEX tail;
    bool running;
    bool error;
    bool selfFilling;
    unsigned selfFillingBytesRead;
    struct timeval selfFillingStartTime;
    
    unsigned dataRate;

    pthread_mutex_t mutex;
    pthread_cond_t cond;
};

#endif // __XM_CIRCULAR_BUFFER_H__
