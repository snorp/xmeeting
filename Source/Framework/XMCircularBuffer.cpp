/*
 * $Id: XMCircularBuffer.cpp,v 1.3 2006/03/14 23:05:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Andreas Fenkart, Hannes Friederich. All rights reserved.
 */

#include "XMCircularBuffer.h"

XMCircularBuffer::XMCircularBuffer(PINDEX len)
: capacity(len + 1),  /* plus sentinel */
head(0), 
tail(0)
{
	buffer = (char *)malloc(capacity*sizeof(char));
	if(!buffer) 
	{
		running = false;
	}
	else
	{
		running = true;
	}

	/*
	 * Mutex to block write thread when buffer is full
	 */
	int rval;
	rval = pthread_mutex_init(&mutex, NULL);
	if(rval != 0)
	{
		running = false;
	}
	  
	rval = pthread_cond_init(&cond, NULL);
	if(rval != 0) 
	{
		running = false;
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

	pthread_mutex_destroy(&mutex);
	pthread_cond_destroy(&cond);
}
 
BOOL XMCircularBuffer::Full()
{
	/* head + 1 == tail */
	return head_next() == tail;
}

BOOL XMCircularBuffer::Empty()
{
	return head == tail;
}

PINDEX XMCircularBuffer::Size()
{
	/* sentinel is outside of occupied area */
	return (head < tail ) ? head + capacity - tail : head - tail; 
}

PINDEX XMCircularBuffer::Free()
{
		return (capacity - Size() - 1 /*sentinel */);
}

PINDEX XMCircularBuffer::head_next()
{
	return ((head + 1) % capacity);
}

// increments the index by inc
inline void XMCircularBuffer::increment_index(PINDEX &index, PINDEX inc)
{
	index += inc;
	index %= capacity;
}

// increments the head
inline void XMCircularBuffer::increment_head(PINDEX inc)
{
	increment_index(head, inc);
}     
    
// increments the tail
inline void XMCircularBuffer::increment_tail(PINDEX inc)
{
	increment_index(tail, inc);
}

int XMCircularBuffer::Fill(const char *inbuf, PINDEX len, Boolean lock, Boolean overwrite)
{
   int done = 0, todo = 0;

   if(inbuf== NULL) // no valid buffer specified
   {
	   return 0;
   }
   
   if(running == false)
   {
	   // we discard any samples but return len to act as if we stored all bytes
	   return len;
   }

   while(done != len && !Full()) 
   {
	   if(head >= tail) 
	   {
		   // head unwrapped, fill from head till end of buffer
		   if(tail == 0) /* buffer[capacity] == sentinel */
		   {
			   todo = MIN(capacity -1 /*sentinel*/ - head, len - done);
		   }
		   else
		   {
			   todo = MIN(capacity - head, len - done);
		   }
	   } 
	   else 
	   {
         // fill from head till tail 
		   todo = MIN(tail -1 /*sentinel*/ - head, len - done);
	   }
	   memcpy(buffer + head, inbuf + done, todo);
	   done += todo;
	   increment_head(todo);
   }

   // What to do if buffer is full and more bytes
   // need to be copied ?  
   if(Full() && done != len && (overwrite || lock)) 
   {
	   if(lock) 
	   {
		   pthread_mutex_lock(&mutex);
		   
		   // wait until buffer is available. Do the necessary check again before
		   // going to sleep
		   if(Full())
		   {
			   pthread_cond_wait(&cond, &mutex);
		   }
		   pthread_mutex_unlock(&mutex);
	   }
	   else if(overwrite)
	   {
		   pthread_mutex_lock(&mutex);
		   if(Full())
		   {
			   tail += len - done; // also shifts sentinel
			   tail %= capacity; // wrap around
		   }
		   pthread_mutex_unlock(&mutex);
	   }
	   
	   // try again
	   done += Fill(inbuf + done, len - done, lock, overwrite);
   }

   // wake up read thread if necessary
   if(!Empty())
   {
      pthread_cond_signal(&cond);
   }
   
   return done;
}


PINDEX XMCircularBuffer::Drain(char *outbuf, PINDEX len, Boolean lock) 
{
   PINDEX done = 0, todo = 0;

	if(outbuf == NULL || running == false)
	{
		return 0;
	}

	/* protect agains buffer corruption when write thread
	 * is overwriting */
	pthread_mutex_lock(&mutex);

	while(done != len && !Empty()) 
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
			if(!Full())
			{
				pthread_cond_wait(&cond, &mutex);
			}
			pthread_mutex_unlock(&mutex); // race with write thread...
			done += Drain(outbuf + done, len - done, lock);
			return done;
		}
	}

	pthread_mutex_unlock(&mutex);

	if(!Full())
	{
      pthread_cond_signal(&cond);
	}
	
	return done;
}

void XMCircularBuffer::Stop()
{
	pthread_mutex_lock(&mutex);
	running = false;
	pthread_mutex_unlock(&mutex);
	
	pthread_cond_broadcast(&cond);
}

void XMCircularBuffer::Restart()
{
	pthread_mutex_lock(&mutex);
	head = 0;
	tail = 0;
	running = true;
	pthread_mutex_unlock(&mutex);
}
