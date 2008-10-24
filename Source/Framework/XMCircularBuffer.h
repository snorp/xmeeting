/*
 * $Id: XMCircularBuffer.h,v 1.8 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Andreas Fenkart, Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CIRCULAR_BUFFER_H__
#define __XM_CIRCULAR_BUFFER_H__

#include <ptlib.h>

/**
 * Simple circular buffer for one producer and consumer with additional
 * 'comfort' functionality. 
 *
 * The implementation uses read/write counts to tell apart full from empty by 
 * the following equations: 
 *
 * full  := read_count + capacity == write_count
 * empty := read_count == write_count
 *
 * We need a lock when updating the read_count, due to the overwrite mechanism
 * in case of buffer overflow. The write_count needs no locking because 
 * overwrite does not make sense in case of buffer underrun. 
 *
 * Keep in mind that this buffer does no know about frames or packets, it's up
 * to you to make sure you get the right number of bytes. In doubt use Size() 
 * to compute how many frames/packets it is save to drain/fill.
 *
 * This buffer does also offer the chance to *stop* the buffer from being used
 * through calling Stop(). After that, any bytes sent to Fill() will just be
 * ignored and Drain zero-fills the outgoing buffer. This method also unblocks any
 * thread locked when calling Fill() or Drain(). So, Stop() allows a third party
 * to interfere with the buffer behaviour and to remove any deadlocks.
 * The call to Restart() will undo the operation above and *start* the buffer
 * again. However, the buffer is considered empty after Restart().
 **/

class XMCircularBuffer
{
  public:

    /**
     * Creates a circular buffer with a capacity of len bytes
     **/
    explicit XMCircularBuffer(unsigned capacity);
    ~XMCircularBuffer();
    
    /** 
     * Inserts up to len bytes into the circular buffer. Returns the amount of bytes 
     * actually written to the buffer. If blockIfFull is true, this method blocks until 
     * all bytes have been written (or the buffer was *stopped*). If overwriteIfFull 
     * is true, the buffer will overwrite unread data. 
     * Note that blockIfFull and overwriteIfFull are mutually exclusive. If blockIfFull
     * is true, overwriteIfFull is ignored.
     **/
    unsigned Fill(const char* inbuf, unsigned len, bool blockIfFull = true, 
                  bool overwriteIfFull = false);

    /** 
     * See also Fill.
     * Returns the amount of bytes read from the buffer. If blockIfEmpty is true,
     * the method blocks until all bytes have been obtained. 
     * If the buffer is stopped, all remaining bytes are set to zero. 
     * If maxWaitTime is smaller than UINT_MAX, the buffer will wait at most
     * maxWaitTime milliseconds for data before the buffer enters a "self-filling"
     * state which lasts until the next call to Fill(). In the self-filling
     * state, Drain() always zero-fills the buffer in the desired length.
     * This is to avoid deadlock-like situations if the source thread does not
     * fill the buffer over a longer period.
     **/
    unsigned Drain(char* outbuf, unsigned len, bool blockIfEmpty = true, 
                   unsigned maxWaitTime = UINT_MAX);
	
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
    unsigned Size();
    
    /**
     * Sets the data rate (in bytes/s) for this buffer. Needed for the selfFilling state
    **/
    void SetDataRate(unsigned _dataRate) { dataRate = _dataRate; }

private:
    static inline bool is_full(unsigned writeCount, unsigned readCount, unsigned capacity);
    static inline bool is_empty(unsigned writeCount, unsigned readCount);
    static inline unsigned get_size(unsigned writeCount, unsigned readCount);
    static inline unsigned get_free(unsigned writeCount, unsigned readCount, unsigned capacity);
    
    static inline unsigned min(unsigned a, unsigned b);
    
    inline int mutex_lock();
    inline int mutex_unlock();
    inline int cond_wait();
    inline int cond_timedwait(unsigned waitTime);
    inline int cond_signal();
    inline int cond_broadcast();
	
    char* buffer;
    const unsigned capacity;
    volatile unsigned writeCount;
    volatile unsigned readCount;
    volatile bool running;
    bool error;
    bool selfFilling;
    unsigned selfFillingBytesRead;
    struct timeval selfFillingStartTime;
    
    unsigned dataRate;

    pthread_mutex_t mutex;
    pthread_cond_t cond;
};

#endif // __XM_CIRCULAR_BUFFER_H__
