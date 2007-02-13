/*
 * $Id: XMCircularBuffer.h,v 1.3 2007/02/13 11:52:11 hfriederich Exp $
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
 * ignored and Drain returns 0 bytes constantly. This method also unblocks any
 * thread locked when calling Fill() or Drain(). So, Stop() allows a third
 * to interfere with the buffer behaviour and to remove any deadlocks.
 * The call to Restart() will undo the operation above and *start* the buffer
 * again. However, the buffer is considered empty after Restart()
 **/

class XMCircularBuffer
{
public:

	explicit XMCircularBuffer(PINDEX len);
	~XMCircularBuffer();
 
	/**
	 * Returns whether the buffer is full/empty or not 
	 **/
	BOOL Full();
	BOOL Empty();

	/**
	 * Returns the Size (in bytes) for this buffer
	 **/
	PINDEX Size();
	
	/**
	 * Returns the number of free bytes for this buffer
	 **/
	PINDEX Free();

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
	 * blocks until all bytes have been obtained. Note that even if lock
	 * is set, this method may return a number smaller than len if the
	 * buffer was *stopped* in the meantime
	 **/
	PINDEX Drain(char* outbuf, PINDEX len, BOOL lock = true);
	
	/**
	 * *Starts* / *Stops* the buffer as desired
	 **/
	void Stop();
	void Restart();

 private:
	inline PINDEX head_next();
	inline void increment_index(PINDEX &index, PINDEX inc);
	inline void increment_head(PINDEX inc);    
	inline void increment_tail(PINDEX inc);
	
   char* buffer;
   const PINDEX capacity;
   PINDEX head, tail;
   BOOL running;

   pthread_mutex_t mutex;
   pthread_cond_t cond;
};

#endif // __XM_CIRCULAR_BUFFER_H__
