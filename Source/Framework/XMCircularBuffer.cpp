/*
 * $Id: XMCircularBuffer.cpp,v 1.5 2007/02/18 19:02:47 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Andreas Fenkart, Hannes Friederich. All rights reserved.
 */

// Note: when resetting the buffer within Restart(),
// there MAY be a rare case that a write thread executing
// Fill() assumes a different value for head, adjusts the
// head variable and thus MAY create up to one complete
// buffer of garbage. As this requires a relatively special
// sequence of calls to Fill(), Stop() and Restart(), which
// is unlikely to occur, there is no mutex protection for this
// case.

#include "XMCircularBuffer.h"

XMCircularBuffer::XMCircularBuffer(PINDEX len)
: capacity(len + 1),  /* plus sentinel */
head(0), 
tail(0)
{
    error = FALSE;
    running = TRUE;
    
	buffer = (char *)malloc(capacity*sizeof(char));
	if(!buffer) 
	{
		error = TRUE;
        running = FALSE;
	}

	/*
	 * Mutex to block write thread when buffer is full
	 */
	int rval;
	rval = pthread_mutex_init(&mutex, NULL);
	if(rval != 0)
	{
        PTRACE(3, "pthread_mutex_init() failed with rval " << rval);
		error = TRUE;
        running = FALSE;
	}
	  
	rval = pthread_cond_init(&cond, NULL);
	if(rval != 0) 
	{
        PTRACE(3, "pthread_cond_init() failed with rval " << rval);
		error = TRUE;
        running = FALSE;
	}
}

XMCircularBuffer::~XMCircularBuffer()
{
	// just to make sure
	Stop();
	
	if(buffer != NULL)
	{
		std::free(buffer);
		buffer = NULL;
	}

	int rval;
    rval = pthread_mutex_destroy(&mutex);
    if(rval != 0) {
        PTRACE(3, "pthread_mutex_destroy() failed with rval " << rval);
    }
	rval = pthread_cond_destroy(&cond);
    if(rval != 0) {
        PTRACE(3, "pthread_cond_destroy() failed with rval " << rval);
    }
}

int XMCircularBuffer::Fill(const char *inbuf, PINDEX len, BOOL lock, BOOL overwrite)
{
    int done = 0, todo = 0;
    int rval;

    if(inbuf== NULL || error == TRUE || len == 0) // no valid buffer specified or an error has occurred
    {
        return 0;
    }
   
    if(running == FALSE)
    {
        // we discard any samples but return len to act as if we stored all bytes
        return len;
    }
    
    // Copy values to local variables
    PINDEX _head = head;
    PINDEX _tail = tail;

    while(done != len && !full(_head, _tail)) 
    {
        if(_head >= _tail) 
        {
            // head unwrapped, fill from head till end of buffer
            if(_tail == 0) /* buffer[capacity] == sentinel */
            {
                todo = MIN(capacity - 1 /*sentinel*/ - _head, len - done);
            }
            else
            {
                todo = MIN(capacity - _head, len - done);
            }
        } 
        else 
        {
            // fill from head till tail 
            todo = MIN(_tail - 1 /*sentinel*/ - _head, len - done);
        }
        memcpy(buffer + _head, inbuf + done, todo);
        done += todo;
        
        increment_head(_head, todo);
        _head = head;
    }

    // What to do if buffer is full and more bytes
    // need to be copied ?  
    if(full(_head, _tail) && done != len && (overwrite || lock)) 
    {
        if(lock) 
        {
            rval = mutex_lock();
            if(rval != 0) {
                return done;
            }
		   
            // wait until buffer is available. Do the necessary check again before
            // going to sleep
            while(running == TRUE && full(head, tail))
            {
                rval = cond_wait();
                if(rval != 0) {
                    mutex_unlock();
                    return done;
                }
            }
            
            BOOL isStillRunning = running;
           
            mutex_unlock();
            
            if (isStillRunning == FALSE) {
                return len; // Buffer no longer runs, simply return len
            }
        }
        else if(overwrite)
        {
            rval = mutex_lock();
            if(rval != 0 || running == FALSE) {
                return done;
            }
            if(full(head, tail))
            {
                tail += len - done; // also shifts sentinel
                tail %= capacity; // wrap around
            }
            
            mutex_unlock();
        }
	   
        // try again
        done += Fill(inbuf + done, len - done, lock, overwrite);
    }

    // wake up read thread if necessary
    if(!empty(head, tail))
    {
        cond_signal();
    }
   
    return done;
}


PINDEX XMCircularBuffer::Drain(char *outbuf, PINDEX len, BOOL lock) 
{
    PINDEX done = 0, todo = 0;
    int rval;

    /* Early abort criteria */
	if(outbuf == NULL || error == TRUE || len == 0) {
        return 0;
    }

	/* protect against buffer corruption when write thread
	 * is overwriting */
	rval = mutex_lock();
    if(rval != 0) {
        return 0; // Treat as an error
    }
    
    if (running == FALSE) { // Fill buffer with zeros and return
        memset(outbuf, 0, len);
        mutex_unlock();
        return len;
    }

	while(done != len && !empty(head, tail)) 
	{
		if(head >= tail) 
		{
			// head unwrapped 
			todo = MIN(head - tail, len - done);
		}
		else 
		{
			// head wrapped 
			todo = MIN(capacity - tail, len - done);
		}        
		memcpy(outbuf + done, buffer + tail, todo);
		done += todo;
		increment_tail(todo);
	}

	// what to do if not as many bytes are available as
	// requested ? If lock is true, we block until more data
	// is available and then try again
	if(done != len && (lock)) /* && Empty() */
	{
		if (lock)
		{
			while(running == TRUE && !full(head, tail))
			{
				rval = cond_wait();
                if(rval != 0) { // Treat as an error - return
                    mutex_unlock();
                    return done;
                }
			}
            
            mutex_unlock(); // race with write thread
            
            // The case (running==FALSE) is handled in this
            // nested call to Drain()
            done += Drain(outbuf + done, len - done, lock);
			return done;
		}
	}
    
    // It might be that the writing thread is waiting for a non-full buffer
    BOOL signal = (done != 0 || !full(head, tail));

	mutex_unlock();

    if (signal == TRUE) {
        cond_signal();
    }
	
	return done;
}

void XMCircularBuffer::Stop()
{
    BOOL needsSignaling;
    
    if(running == FALSE || error == TRUE) {
        return;
    }
    
    // Protect with a lock in case multiple threads are calling
    // either Stop() or Restart() simultaneously
    mutex_lock();
    needsSignaling = (running == TRUE);
	running = FALSE;
	mutex_unlock();
	
    // Wake up any threads that are waiting on the condition variable.
    // This is to avoid deadlocks, as cond_signal() is never called while
    // running == FALSE
    if(needsSignaling)
    {
        cond_broadcast();
    }
}

void XMCircularBuffer::Restart()
{
	int rval;
    
    if(running == TRUE || error == TRUE) {
        return;
    }
    
    rval = mutex_lock();
    if(rval != 0) {
        return;
    }

    // Reset the variables to make the buffer empty
	head = 0;
	tail = 0;
	running = TRUE;
    mutex_unlock();
}

BOOL XMCircularBuffer::Full()
{
    int rval = mutex_lock();
    if (rval != 0) {
        return FALSE;
    }
    BOOL is_full = (running == TRUE && full(head, tail));
    mutex_unlock();
    return is_full;
}

BOOL XMCircularBuffer::Empty()
{
    int rval = mutex_lock();
    if (rval != 0) {
        return TRUE;
    }
    BOOL is_empty = (running == FALSE || empty(head, tail));
    mutex_unlock();
    return is_empty;
}

PINDEX XMCircularBuffer::Size()
{
    int rval = mutex_lock();
    if (rval != 0) {
        return 0;
    }
    PINDEX current_size = (running == TRUE) ? size(head, tail) : 0;
    mutex_unlock();
    return current_size;
}

inline BOOL XMCircularBuffer::full(PINDEX _head, PINDEX _tail) const
{
	/* head + 1 == tail */
    PINDEX head_next = ((_head + 1) % capacity);
	return (head_next == _tail);
}

inline BOOL XMCircularBuffer::empty(PINDEX _head, PINDEX _tail) const
{
	return (_head == _tail);
}

inline PINDEX XMCircularBuffer::size(PINDEX _head, PINDEX _tail) const
{
	/* sentinel is outside of occupied area */
	return (_head < _tail ) ? _head + capacity - _tail : _head - _tail; 
}

inline PINDEX XMCircularBuffer::free(PINDEX _head, PINDEX _tail) const
{
    return (capacity - size(_head, _tail) - 1 /*sentinel */);
}

// increments the head
inline void XMCircularBuffer::increment_head(PINDEX currentHead, PINDEX inc)
{
    // calculate new head index
    PINDEX newHead = currentHead + inc;
    newHead %= capacity;
    
    // write into member variable
    head = newHead;
}     

// increments the tail
inline void XMCircularBuffer::increment_tail(PINDEX inc)
{
    tail += inc;
    tail %= capacity;
}

inline int XMCircularBuffer::mutex_lock()
{
    int rval = pthread_mutex_lock(&mutex);
    if (rval != 0) {
        PTRACE(3, "pthread_mutex_lock() failed with rval " << rval);
    }
    return rval;
}

inline int XMCircularBuffer::mutex_unlock()
{
    int rval = pthread_mutex_unlock(&mutex);
    if (rval != 0) {
        PTRACE(3, "pthread_mutex_unlock() failed with rval " << rval);
    }
    return rval;
}

inline int XMCircularBuffer::cond_wait()
{
    int rval = pthread_cond_wait(&cond, &mutex);
    if (rval != 0) {
        PTRACE(3, "pthread_cond_wait() failed with rval " << rval);
    }
    return rval;
}

inline int XMCircularBuffer::cond_signal()
{
    int rval = pthread_cond_signal(&cond);
    if (rval != 0) {
        PTRACE(3, "pthread_cond_signal() failed with rval " << rval);
    }
    return rval;
}

inline int XMCircularBuffer::cond_broadcast()
{
    int rval = pthread_cond_broadcast(&cond);
    if (rval != 0) {
        PTRACE(3, "pthread_cond_broadcasst() failed with rval " << rval);
    }
    return rval;
}

