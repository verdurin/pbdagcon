#pragma once

#include <exception>

///
/// Exceptions thrown by derived classes
///
namespace PacBio {
namespace DagCon {
    class IOException : public std::exception {
    public:
        IOException(const char* desc);
        virtual const char* what() const throw() {
            return desc_;
        }
    private:
        const char* desc_;
    };

    class MemoryException : public std::exception {
    public:
        virtual const char* what() const throw() {
            return "Failed to allocate memory";
        }
    };
}}


///
/// Generic alignment provider interface.
///
class AlnProvider {
public:
    /// Gets the set of alignments for the next target and puts them into the
    /// given vector.  Note this function will clear the contents of the vector
    /// prior to adding the next set of alignments.
    /// \param dest reference to a vector to hold the alignments.
    /// \return True if there are more targets, otherwise false.
    virtual bool nextTarget(std::vector<dagcon::Alignment>& dest) = 0;

    /// Same as nextTarget(dest), except it also returns the target sequence we are
    /// going to correct.
    virtual bool nextTarget(std::string& targSeq, std::vector<dagcon::Alignment>& dest) = 0;

    virtual ~AlnProvider() {};
};
