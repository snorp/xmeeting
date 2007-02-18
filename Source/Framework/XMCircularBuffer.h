/*
 * $Id: XMCircularBuffer.h,v 1.4 2007/02/18 19:02:47 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Andreas Fenkart, Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CIRCULAR_BUFFER_H__
#define __XM_CIRCULAR_BUFFER_H__

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
	PINDEX Fill(const char* inbuf, PINDEX len, BOOL lock = true, 
				BOOL overwrite = false);


	/** 
	 * See also Fill.
	 * Returns the amount of bytes read from the buffer. If lock is true,
	 * blocks until all bytes have been obtained. If the buffer is stopped,
     * all remaining bytes are set to zero.
	 **/
	PINDEX Drain(char* outbuf, PINDEX len, BOOL lock = true);
	
	/**
	 * *Starts* / *Stops* the buffer as desired
	 **/
	void Stop();
	void Restart();
    
    /**
     * Returns if the buffer is currently full
     **/
    BOOL Full();
    
    /**
     * Returns if the buffer is currently empty
     **/
    BOOL Empty();
    
    /**
     * Returns the number of bytes currently in the buffer
     **/
    PINDEX Size();

 private:
    inline BOOL full(PINDEX _head, PINDEX _tail) const;
    inline BOOL empty(PINDEX _head, PINDEX _tail) const;
    inline PINDEX size(PINDEX _head, PINDEX _tail) const;
    inline PINDEX free(PINDEX _head, PINDEX _tail) const;
    
	inline void increment_head(PINDEX currentHead, PINDEX inc);    
	inline void increment_tail(PINDEX inc);
    
    inline int mutex_lock();
    inline int mutex_unlock();
    inline int cond_wait();
    inline int cond_signal();
    inline int cond_broadcast();
	
    char* buffer;
    const PINDEX capacity;
    volatile PINDEX head;
    volatile PINDEX tail;
    BOOL running;
    BOOL error;

    pthread_mutex_t mutex;
    pthread_cond_t cond;
};

#endif // __XM_CIRCULAR_BUFFER_H__
