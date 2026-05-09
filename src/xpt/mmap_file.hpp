#pragma once

// POSIX-only memory-mapped file wrapper for the XPT reader.
// Provides a zero-copy view into the file. The OS pages bytes in/out under
// memory pressure, so the mapped region does not count against the parser's
// scratch-memory budget.

#include <cstddef>
#include <cstdint>
#include <stdexcept>
#include <string>

#include <fcntl.h>
#include <sys/fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

namespace cxpt {

class MappedFile {
public:
    MappedFile() = default;
    explicit MappedFile(const std::string &path) { open(path); }
    ~MappedFile() { close(); }

    MappedFile(const MappedFile &) = delete;
    MappedFile &operator=(const MappedFile &) = delete;

    MappedFile(MappedFile &&other) noexcept
        : data_(other.data_), size_(other.size_), fd_(other.fd_) {
        other.data_ = nullptr;
        other.size_ = 0;
        other.fd_ = -1;
    }
    MappedFile &operator=(MappedFile &&other) noexcept {
        if (this != &other) {
            close();
            data_ = other.data_;
            size_ = other.size_;
            fd_ = other.fd_;
            other.data_ = nullptr;
            other.size_ = 0;
            other.fd_ = -1;
        }
        return *this;
    }

    void open(const std::string &path) {
        close();
        fd_ = ::open(path.c_str(), O_RDONLY
#ifdef O_CLOEXEC
                                       | O_CLOEXEC
#endif
        );
        if (fd_ < 0) {
            throw std::runtime_error("Cannot open file: " + path);
        }
        struct stat st{};
        if (::fstat(fd_, &st) != 0) {
            ::close(fd_);
            fd_ = -1;
            throw std::runtime_error("fstat failed: " + path);
        }
        size_ = static_cast<std::size_t>(st.st_size);
        if (size_ == 0) {
            return;  // empty file; data_ stays null
        }
        void *p = ::mmap(nullptr, size_, PROT_READ, MAP_PRIVATE, fd_, 0);
        if (p == MAP_FAILED) {
            ::close(fd_);
            fd_ = -1;
            size_ = 0;
            throw std::runtime_error("mmap failed: " + path);
        }
#ifdef MADV_SEQUENTIAL
        ::madvise(p, size_, MADV_SEQUENTIAL);
#endif
#ifdef MADV_WILLNEED
        ::madvise(p, size_, MADV_WILLNEED);
#endif
        data_ = static_cast<const std::uint8_t *>(p);
    }

    void close() noexcept {
        if (data_ != nullptr) {
            ::munmap(const_cast<std::uint8_t *>(data_), size_);
            data_ = nullptr;
        }
        size_ = 0;
        if (fd_ >= 0) {
            ::close(fd_);
            fd_ = -1;
        }
    }

    [[nodiscard]] const std::uint8_t *data() const noexcept { return data_; }
    [[nodiscard]] std::size_t size() const noexcept { return size_; }
    [[nodiscard]] bool isOpen() const noexcept { return data_ != nullptr || size_ == 0; }

private:
    const std::uint8_t *data_ = nullptr;
    std::size_t size_ = 0;
    int fd_ = -1;
};

}  // namespace cxpt
