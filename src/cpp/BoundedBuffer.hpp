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

    BoundedBuffer(size_t max) : max_(max) { }

    void push(T item) {
        std::unique_lock<std::mutex> lock(mutex_);
        not_full_.wait(lock, [this](){return buffer_.size() != max_;});
        buffer_.push_front(item);
        not_empty_.notify_one();
    }

    void pop(T* pItem) {
        std::unique_lock<std::mutex> lock(mutex_);
        not_empty_.wait(lock, [this](){return buffer_.size() != 0U;});
        *pItem = buffer_.back();
        buffer_.pop_back();
        not_full_.notify_one();
    }

    unsigned int size() {
        return buffer_.size();
    }

private:
    size_t max_;
    buffer_type buffer_;
    std::mutex mutex_;
    std::condition_variable not_empty_;
    std::condition_variable not_full_;
};

#endif // __GCON_BOUNDEDBUFFER__

