// Copyright (c) 2011-2015, Pacific Biosciences of California, Inc.
//
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted (subject to the limitations in the
// disclaimer below) provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//
// * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following
// disclaimer in the documentation and/or other materials provided
// with the distribution.
//
// * Neither the name of Pacific Biosciences nor the names of its
// contributors may be used to endorse or promote products derived
// from this software without specific prior written permission.
//
// NO EXPRESS OR IMPLIED LICENSES TO ANY PARTY'S PATENT RIGHTS ARE
// GRANTED BY THIS LICENSE. THIS SOFTWARE IS PROVIDED BY PACIFIC
// BIOSCIENCES AND ITS CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
// WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL PACIFIC BIOSCIENCES OR ITS
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
// USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
// SUCH DAMAGE.

#ifndef __GCON_BOUNDEDBUFFER__
#define __GCON_BOUNDEDBUFFER__

#include <deque>
#include <condition_variable>
#include <mutex>
#include <functional>
#include <vector>
#include <string>
#include "Alignment.hpp"

///
/// Templated, thread-safe buffer container, uses uses boost::circular buffer
/// bounded by a given capacity specified by the caller.  When the buffer is
/// full, the push waits for an open spot.  When the buffer is empty, the pop
/// waits for an item to be present.  Condition variables are used to signal
/// the state of the buffer.
///
template <class T>
class BoundedBuffer {
public:
    typedef std::deque<T> buffer_type;

    BoundedBuffer(int max) : max_(max) { }

    void push(T item) {
        std::unique_lock<std::mutex> lock(mutex_);
        not_full_.wait(lock, [this](){return buffer_.size() != max_;});
        buffer_.push_front(item);
        not_empty_.notify_one();
    }

    void pop(T* pItem) {
        std::unique_lock<std::mutex> lock(mutex_);
        not_empty_.wait(lock, [this](){return buffer_.size() != 0;});
        *pItem = buffer_.back();
        buffer_.pop_back();
        not_full_.notify_one();
    }

    unsigned int size() {
        return buffer_.size();
    }

private:
    int max_;
    buffer_type buffer_;
    std::mutex mutex_;
    std::condition_variable not_empty_;
    std::condition_variable not_full_;
};

#endif // __GCON_BOUNDEDBUFFER__

