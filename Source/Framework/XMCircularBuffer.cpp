/*
 * $Id: XMCircularBuffer.cpp,v 1.7 2008/08/14 19:57:05 hfriederich Exp $
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
    error = false;
    running = true;
    
	buffer = (char *)malloc(capacity*sizeof(char));
	if(!buffer) 
	{
		error = true;
        running = false;
	}

	/*
	 * Mutex to block write thread when buffer is full
	 */
	int rval;
	rval = pthread_mutex_init(&mutex, NULL);
	if(rval != 0)
	{
        PTRACE(3, "pthread_mutex_init() failed with rval " << rval);
		error = true;
        running = false;
	}
	  
	rval = pthread_cond_init(&cond, NULL);
	if(rval != 0) 
	{
        PTRACE(3, "pthread_cond_init() failed with rval " << rval);
		error = true;
        running = false;
	}
    
    selfFilling = false;
    dataRate = 0;
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

int XMCircularBuffer::Fill(const char *inbuf, PINDEX len, bool lock, bool overwrite)
{
    int done = 0, todo = 0;
    int rval;
    
    selfFilling = false; // reset the self-filling condition

    if(inbuf== NULL || error == true || len == 0) // no valid buffer specified or an error has occurred
    {
        return 0;
    }
   
    if(running == false)
    {
        // we discard any samples but return len to act as if we stored all bytes
        return len;
    }

    while(done != len && !full()) 
    {
        if(head >= tail) 
        {
            // head unwrapped, fill from head till end of buffer
            if(tail == 0) /* buffer[capacity] == sentinel */
            {
                todo = MIN(capacity - 1 /*sentinel*/ - head, len - done);
            }
            else
            {
                todo = MIN(capacity - head, len - done);
            }
        } 
        else 
        {
            // fill from head till tail 
            todo = MIN(tail - 1 /*sentinel*/ - head, len - done);
        }
        memcpy(buffer + head, inbuf + done, todo);
        done += todo;
        
        increment_head(todo);
    }

    // What to do if buffer is full and more bytes
    // need to be copied ?  
    if(full() && done != len && (overwrite || lock)) 
    {
        if(lock) 
        {
            rval = mutex_lock();
            if(rval != 0) {
                return done;
            }
		   
            // wait until buffer is available. Do the necessary check again before
            // going to sleep
            while (running == true && full())
            {
                rval = cond_wait();
                if(rval != 0) {
                    mutex_unlock();
                    return done;
                }
            }
            
            bool isStillRunning = running;
           
            mutex_unlock();
            
            if (isStillRunning == false) {
                return len; // Buffer no longer runs, simply return len
            }
        }
        else if(overwrite)
        {
            rval = mutex_lock();
            if(rval != 0) {
                return done; // error
            }
            if(running == false) {
                mutex_unlock();
                return done;
            }
            if(full())
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
    if(!empty())
    {
        cond_signal();
    }
   
    return done;
}


PINDEX XMCircularBuffer::Drain(char *outbuf, PINDEX len, bool lock, unsigned maxWaitTime) 
{
    PINDEX done = 0, todo = 0;
    int rval;

    // Early abort criteria
	if(outbuf == NULL || error == true || len == 0) {
        return 0;
    }

	/* protect against buffer corruption when write thread
	 * is overwriting */
	rval = mutex_lock();
    if(rval != 0) {
        return 0; // Treat as an error
    }
    
    if (running == false || selfFilling == true) { // Fill buffer with zeros and return
        bzero(outbuf, len);
        mutex_unlock();
        
        if(dataRate != 0)
        {
            // Determine how long to sleep.
            // This is required to obtain the correct target data rate
            struct timeval currentTime;
            gettimeofday(&currentTime, NULL);
            selfFillingBytesRead += len;
            unsigned millisecondsSinceStart = (unsigned)(float(selfFillingBytesRead) * 1000 /(float)dataRate);
            unsigned timeElapsed = ((currentTime.tv_sec - selfFillingStartTime.tv_sec) * 1000) +
                                   ((currentTime.tv_usec - selfFillingStartTime.tv_usec) / 1000);
            int timeToWait = millisecondsSinceStart - timeElapsed;
            
            if (timeToWait > 0) {
                // Sleep the desired amount
                usleep(1000 * timeToWait);
            }
        }
        return len;
    }

	while(done != len && !empty()) 
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
	if(done != len && (lock))
	{
        if (maxWaitTime == UINT_MAX)
        {
            while (running == true && empty())
            {
                rval = cond_wait();
                if (rval != 0) { // Treat as an error - return
                    mutex_unlock();
                    return done;
                }
            }
        } 
        else
        {
            while (running == true && empty())
            {
                rval = cond_timedwait(maxWaitTime);
                if (rval == ETIMEDOUT) {
                    selfFilling = true; // Enter self-filling state
                    selfFillingBytesRead = 0;
                    gettimeofday(&selfFillingStartTime, NULL);
                    break;
                } else if (rval != 0) { // Treat as an error - return
                    mutex_unlock();
                    return done;
                }
            }
        }
            
        mutex_unlock(); // race with write thread
            
        // The case (running==false) is handled in this
        // nested call to Drain()
        done += Drain(outbuf + done, len - done, lock);
        return done;
	}
    
    // It might be that the writing thread is waiting for a non-full buffer
    bool signal = !full();

	mutex_unlock();

    if (signal == true) {
        cond_signal();
    }
	
	return done;
}

void XMCircularBuffer::Stop()
{
    bool needsSignaling;
    
    if(running == false || error == true) {
        return;
    }
    
    // Protect with a lock in case multiple threads are calling
    // either Stop() or Restart() simultaneously
    mutex_lock();
    needsSignaling = (running == true);
	running = false;
    selfFillingBytesRead = 0;
    gettimeofday(&selfFillingStartTime, NULL);
	mutex_unlock();
	
    // Wake up any threads that are waiting on the condition variable.
    // This is to avoid deadlocks, as cond_signal() is never called while
    // running == false
    if(needsSignaling)
    {
        cond_broadcast();
    }
}

void XMCircularBuffer::Restart()
{
	int rval;
    
    if(running == true || error == true) {
        return;
    }
    
    rval = mutex_lock();
    if(rval != 0) {
        return;
    }

    // Reset the variables to make the buffer empty
	head = 0;
	tail = 0;
	running = true;
    mutex_unlock();
}

bool XMCircularBuffer::Full()
{
    int rval = mutex_lock();
    if (rval != 0) {
        return false;
    }
    bool is_full = (running == true && full());
    mutex_unlock();
    return is_full;
}

bool XMCircularBuffer::Empty()
{
    int rval = mutex_lock();
    if (rval != 0) {
        return true;
    }
    bool is_empty = (running == false || empty());
    mutex_unlock();
    return is_empty;
}

PINDEX XMCircularBuffer::Size()
{
    int rval = mutex_lock();
    if (rval != 0) {
        return 0;
    }
    PINDEX current_size = (running == true) ? size() : 0;
    mutex_unlock();
    return current_size;
}

inline bool XMCircularBuffer::full() const
{
	/* head + 1 == tail */
    PINDEX head_next = ((head + 1) % capacity);
	return (head_next == tail);
}

inline bool XMCircularBuffer::empty() const
{
	return (head == tail);
}

inline PINDEX XMCircularBuffer::size() const
{
	/* sentinel is outside of occupied area */
	return (head < tail ) ? head + capacity - tail : head - tail; 
}

inline PINDEX XMCircularBuffer::free() const
{
    return (capacity - size() - 1 /*sentinel */);
}

// increments the head
inline void XMCircularBuffer::increment_head(PINDEX inc)
{
    head += inc;
    head %= capacity;
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

inline int XMCircularBuffer::cond_timedwait(unsigned waitTime)
{
    struct timeval currentTime;
    struct timespec wakeupTime;
    gettimeofday(&currentTime, NULL);
    
    wakeupTime.tv_sec = currentTime.tv_sec;
    wakeupTime.tv_nsec = (currentTime.tv_usec * 1000 ) + (waitTime * 1000 * 1000);
    
    int rval = pthread_cond_timedwait(&cond, &mutex, &wakeupTime);
    if (rval == EINVAL) {
        PTRACE(3, "pthread_cond_timedwait() failed");
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

