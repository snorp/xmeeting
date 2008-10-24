/*
 * $Id: XMCircularBuffer.cpp,v 1.9 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Andreas Fenkart, Hannes Friederich. All rights reserved.
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

XMCircularBuffer::XMCircularBuffer(unsigned _capacity)
: capacity(_capacity),
  writeCount(0), 
  readCount(0),
  error(false),
  running(true),
  selfFilling(false),
  selfFillingBytesRead(0)
{
    
  buffer = new char[capacity];
  if (!buffer) {
    error = true;
    running = false;
  }

  //Mutex to block write thread when buffer is full
  int rval = pthread_mutex_init(&mutex, NULL);
  if (rval != 0) {
    PTRACE(3, "pthread_mutex_init() failed with rval " << rval);
    error = true;
    running = false;
  }
	  
  rval = pthread_cond_init(&cond, NULL);
  if (rval != 0) {
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
	
	delete buffer;
  buffer = NULL;

  int rval = pthread_mutex_destroy(&mutex);
  if (rval != 0) {
    PTRACE(3, "pthread_mutex_destroy() failed with rval " << rval);
  }
  rval = pthread_cond_destroy(&cond);
  if (rval != 0) {
    PTRACE(3, "pthread_cond_destroy() failed with rval " << rval);
  }
}

unsigned XMCircularBuffer::Fill(const char *inbuf, unsigned len, bool blockIfFull, bool overwriteIfFull)
{
  int rval;
  
   // reset the self-filling condition
  selfFilling = false;

  // check input validity
  if (inbuf== NULL || error == true || len == 0) {
    return 0;
  }
   
  if (running == false) {
    // we discard any samples but return len to act as if we stored all bytes
    return len;
  }
  
  // fill as many bytes into the buffer as possible
  unsigned done = 0;
  unsigned localReadCount = readCount; // access the readCount only once per copy cycle
  while (done != len && !is_full(writeCount, localReadCount, capacity))  {
    
    unsigned start = writeCount % capacity;
    unsigned free = get_free(writeCount, localReadCount, capacity);
    
    // don't write past buffer boundary
    unsigned todo = min(capacity-start, free);
    todo = min(todo, len-done);
  
    memcpy(buffer + start, inbuf + done, todo);
    
    done += todo;
    writeCount += todo;
    
    // update the local read count variable
    localReadCount = readCount;
  }

  // What to do if buffer is full and more bytes need to be copied ?  
  if (done != len && (overwriteIfFull || blockIfFull)) {
    if (blockIfFull) {
      rval = mutex_lock();
      if (rval != 0) { // bail out if locking the mutex failed
        return done;
      }
		   
      // wait until buffer is available. Do the necessary check again before waiting
      while (running == true && is_full(writeCount, readCount, capacity)) {
        rval = cond_wait();
        if (rval != 0) { // bail out if cond_wait failed
          mutex_unlock();
          return done;
        }
      }
            
      bool isStillRunning = running;
           
      mutex_unlock();
      
      // if the buffer no longer runs, simply return len
      if (isStillRunning == false) {
        return len;
      }
      
    } else if (overwriteIfFull) {
      // advance the read counter. this has to be protected by the mutex
      rval = mutex_lock();
      if (rval != 0) {
        return done; // bail out if locking the mutex failed
      }
      
      // if the buffer no longer runs, simply return len
      if (running == false) {
        mutex_unlock();
        return len;
      }
      
      // update the read index. recheck the is_full condition, as the
      // reader might have read some bytes meanwhile
      if (is_full(writeCount, readCount, capacity)) {
        readCount += (len-done);
      }
            
      mutex_unlock();
    }
	   
    // try again
    done += Fill(inbuf + done, len - done, blockIfFull, overwriteIfFull);
  }

  // wake up read thread if necessary
  if (!is_empty(writeCount, readCount)) {
    cond_signal();
  }

  return done;
}


unsigned XMCircularBuffer::Drain(char *outbuf, unsigned len, bool blockIfEmpty, unsigned maxWaitTime) 
{
  int rval;

  // check input validity
  if (outbuf == NULL || error == true || len == 0) {
    return 0;
  }

  // protect against buffer corruption when write thread is overwriting
	rval = mutex_lock();
  if (rval != 0) { // bail out if mutex locking failed
    return 0;
  }
  
  // If the buffer isn't running or is in the selfFilling condition,
  // fill the output buffer with zeros and return
  if (running == false || selfFilling == true) {
    bzero(outbuf, len);
    mutex_unlock();
        
    if (dataRate != 0) {
      // Determine how long to sleep.
      // This is required to obtain the correct target data rate, as the reader does not have any
      // rate adaption itself.
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

  // read as many bytes as possible
  unsigned done = 0;
  unsigned localWriteCount = writeCount; // access the writeCount only once per copy cycle
	while (done != len && !is_empty(localWriteCount, readCount)) {
    unsigned start = readCount % capacity;
    unsigned size = get_size(localWriteCount, readCount);
    
    // Don't read past the buffer boundary
    unsigned todo = min(capacity-start, size);
    todo = min(todo, len-done);
  
    memcpy(outbuf + done, buffer + start, todo);
    done += todo;
    readCount += todo;
    
    // update the lcoal writeCount variable
    localWriteCount = writeCount;
  }

  // what to do if not as many bytes are available as
  // requested ? If lock is true, we block until more data
  // is available and then try again
  if (done != len && blockIfEmpty) {
    if (maxWaitTime == UINT_MAX) {
      while (running == true && is_empty(writeCount, readCount)) {
        rval = cond_wait();
        if (rval != 0) { // Treat as an error - return
          mutex_unlock();
          return done;
        }
      }
    } else {
      while (running == true && is_empty(writeCount, readCount)) {
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
    done += Drain(outbuf + done, len - done, blockIfEmpty);
    return done;
  }
    
  // It might be that the writing thread is waiting for a non-full buffer
  bool signal = !is_full(writeCount, readCount, capacity);

  mutex_unlock();

  if (signal == true) {
    cond_signal();
  }
	
  return done;
}

void XMCircularBuffer::Stop()
{
  bool needsSignaling;
    
  if (running == false || error == true) {
    return;
  }
    
  // Protect with a lock in case multiple threads are calling
  // either Stop() or Restart() simultaneously
  mutex_lock();
  needsSignaling = running; 
  running = false;
  selfFillingBytesRead = 0;
  gettimeofday(&selfFillingStartTime, NULL);
  mutex_unlock();
	
  // Wake up any threads that are waiting on the condition variable.
  // This is to avoid deadlocks, as cond_signal() is never called while
  // running == false
  if (needsSignaling) {
    cond_broadcast();
  }
}

void XMCircularBuffer::Restart()
{
  int rval;
    
  if (running == true || error == true) {
    return;
  }
    
  rval = mutex_lock();
  if (rval != 0) {
    return;
  }

  // Reset the variables to make the buffer empty
  writeCount = 0;
  readCount = 0;
  running = true;
  mutex_unlock();
}

bool XMCircularBuffer::Full()
{
  // protect access with a mutex
  int rval = mutex_lock();
  if (rval != 0) {
    return false;
  }
  bool isFull = (running == true && is_full(writeCount, readCount, capacity));
  mutex_unlock();
  return isFull;
}

bool XMCircularBuffer::Empty()
{
  // protect access with a mutex
  int rval = mutex_lock();
  if (rval != 0) {
    return true;
  }
  bool isEmpty = (running == false || is_empty(writeCount, readCount));
  mutex_unlock();
  return isEmpty;
}

unsigned XMCircularBuffer::Size()
{
  // protect access with a mutex
  int rval = mutex_lock();
  if (rval != 0) {
    return 0;
  }
  unsigned current_size = (running == true) ? get_size(writeCount, readCount) : 0;
  mutex_unlock();
  return current_size;
}

inline bool XMCircularBuffer::is_full(unsigned writeCount, unsigned readCount, unsigned capacity)
{
  return (writeCount - capacity) == readCount;
}

inline bool XMCircularBuffer::is_empty(unsigned writeCount, unsigned readCount)
{
  return writeCount == readCount;
}

inline unsigned XMCircularBuffer::get_size(unsigned writeCount, unsigned readCount)
{
  return writeCount - readCount;
}

inline unsigned XMCircularBuffer::get_free(unsigned writeCount, unsigned readCount, unsigned capacity)
{
  return capacity - get_size(writeCount, readCount);
}

inline unsigned XMCircularBuffer::min(unsigned a, unsigned b)
{
  return (a < b) ? a : b;
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

