#include "Vtb_debug_openocd.h"
#include "verilated.h"

#include <arpa/inet.h>
#include <cerrno>
#include <csignal>
#include <cstdint>
#include <cstring>
#include <fcntl.h>
#include <iostream>
#include <netinet/in.h>
#include <string>
#include <sys/socket.h>
#include <unistd.h>

static vluint64_t main_time = 0;
double sc_time_stamp() { return static_cast<double>(main_time); }

static volatile std::sig_atomic_t stop_requested = 0;

static void handle_signal(int) {
    stop_requested = 1;
}

static bool write_all(int fd, const char *buf, size_t len) {
    size_t sent = 0;
    while (sent < len) {
        ssize_t n = ::write(fd, buf + sent, len - sent);
        if (n > 0) {
            sent += static_cast<size_t>(n);
        } else if (n < 0 && (errno == EINTR || errno == EAGAIN || errno == EWOULDBLOCK)) {
            continue;
        } else {
            return false;
        }
    }
    return true;
}

class Sim {
public:
    explicit Sim(Vtb_debug_openocd *top) : top_(top) {
        top_->clk = 0;
        top_->resetn = 0;
        top_->tck = 0;
        top_->tms = 1;
        top_->tdi = 0;
        top_->eval();
    }

    void cycle() {
        top_->clk = 0;
        top_->eval();
        ++main_time;
        top_->clk = 1;
        top_->eval();
        ++main_time;
    }

    void cycles(unsigned n) {
        for (unsigned i = 0; i < n && !Verilated::gotFinish(); ++i)
            cycle();
    }

    void set_reset(bool asserted) {
        top_->resetn = asserted ? 0 : 1;
    }

    void set_jtag(uint8_t tck, uint8_t tms, uint8_t tdi) {
        top_->tck = tck;
        top_->tms = tms;
        top_->tdi = tdi;
    }

    char tdo_char() const {
        return top_->tdo ? '1' : '0';
    }

    void power_on() {
        set_reset(true);
        cycles(8);
        set_reset(false);
        cycles(32);
    }

private:
    Vtb_debug_openocd *top_;
};

class RemoteBitbangServer {
public:
    explicit RemoteBitbangServer(uint16_t port) {
        listen_fd_ = ::socket(AF_INET, SOCK_STREAM, 0);
        if (listen_fd_ < 0)
            fatal("socket");

        int reuse = 1;
        if (::setsockopt(listen_fd_, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse)) < 0)
            fatal("setsockopt");

        sockaddr_in addr {};
        addr.sin_family = AF_INET;
        addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
        addr.sin_port = htons(port);

        if (::bind(listen_fd_, reinterpret_cast<sockaddr *>(&addr), sizeof(addr)) < 0)
            fatal("bind");
        if (::listen(listen_fd_, 1) < 0)
            fatal("listen");
        set_nonblocking(listen_fd_);

        socklen_t len = sizeof(addr);
        if (::getsockname(listen_fd_, reinterpret_cast<sockaddr *>(&addr), &len) < 0)
            fatal("getsockname");
        std::cout << "REMOTE_BITBANG_READY port=" << ntohs(addr.sin_port) << std::endl;
    }

    ~RemoteBitbangServer() {
        if (client_fd_ >= 0)
            ::close(client_fd_);
        if (listen_fd_ >= 0)
            ::close(listen_fd_);
    }

    bool connected() const {
        return client_fd_ >= 0;
    }

    bool accept_if_needed() {
        if (connected())
            return true;

        int fd = ::accept(listen_fd_, nullptr, nullptr);
        if (fd < 0) {
            if (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR)
                return false;
            fatal("accept");
        }

        set_nonblocking(fd);
        client_fd_ = fd;
        ever_connected_ = true;
        std::cout << "REMOTE_BITBANG_ACCEPTED" << std::endl;
        return true;
    }

    bool ever_connected() const {
        return ever_connected_;
    }

    bool process_available(Sim &sim) {
        if (!accept_if_needed())
            return true;

        char buf[4096];
        ssize_t n = ::read(client_fd_, buf, sizeof(buf));
        if (n < 0) {
            if (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR)
                return true;
            fatal("read");
        }
        if (n == 0) {
            std::cout << "REMOTE_BITBANG_DISCONNECT" << std::endl;
            return false;
        }

        for (ssize_t i = 0; i < n; ++i) {
            if (!execute_command(buf[i], sim))
                return false;
        }
        return true;
    }

private:
    static void set_nonblocking(int fd) {
        int flags = ::fcntl(fd, F_GETFL, 0);
        if (flags < 0)
            fatal("fcntl(F_GETFL)");
        if (::fcntl(fd, F_SETFL, flags | O_NONBLOCK) < 0)
            fatal("fcntl(F_SETFL)");
    }

    [[noreturn]] static void fatal(const char *what) {
        std::cerr << "remote_bitbang " << what << " failed: " << std::strerror(errno)
                  << " (" << errno << ")" << std::endl;
        std::exit(1);
    }

    bool execute_command(char c, Sim &sim) {
        if (c >= '0' && c <= '7') {
            uint8_t value = static_cast<uint8_t>(c - '0');
            sim.set_jtag((value >> 2) & 1, (value >> 1) & 1, value & 1);
            sim.cycles(1);
            return true;
        }

        switch (c) {
        case 'R': {
            char out = sim.tdo_char();
            if (!write_all(client_fd_, &out, 1)) {
                std::cerr << "remote_bitbang write failed: " << std::strerror(errno)
                          << " (" << errno << ")" << std::endl;
                return false;
            }
            sim.cycles(1);
            return true;
        }
        case 'r':
        case 's':
        case 't':
        case 'u': {
            unsigned reset_bits = static_cast<unsigned>(c - 'r');
            bool srst = (reset_bits & 1U) != 0;
            bool trst = (reset_bits & 2U) != 0;
            sim.set_reset(srst || trst);
            sim.cycles(8);
            return true;
        }
        case 'B':
        case 'b':
            sim.cycles(1);
            return true;
        case 'Q':
            std::cout << "REMOTE_BITBANG_QUIT" << std::endl;
            return false;
        default:
            std::cerr << "remote_bitbang ignored unsupported command 0x"
                      << std::hex << static_cast<unsigned>(static_cast<unsigned char>(c))
                      << std::dec << std::endl;
            sim.cycles(1);
            return true;
        }
    }

    int listen_fd_ = -1;
    int client_fd_ = -1;
    bool ever_connected_ = false;
};

static uint16_t parse_port(int argc, char **argv) {
    uint16_t port = 9824;
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--port" && i + 1 < argc) {
            int parsed = std::stoi(argv[++i]);
            if (parsed <= 0 || parsed > 65535) {
                std::cerr << "Invalid --port " << parsed << std::endl;
                std::exit(2);
            }
            port = static_cast<uint16_t>(parsed);
        } else if (arg == "--help") {
            std::cout << "usage: " << argv[0] << " [--port PORT]" << std::endl;
            std::exit(0);
        } else {
            std::cerr << "Unknown argument: " << arg << std::endl;
            std::exit(2);
        }
    }
    return port;
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    std::signal(SIGTERM, handle_signal);
    std::signal(SIGINT, handle_signal);

    uint16_t port = parse_port(argc, argv);
    Vtb_debug_openocd top;
    Sim sim(&top);
    sim.power_on();

    RemoteBitbangServer server(port);
    while (!stop_requested && !Verilated::gotFinish()) {
        bool keep_running = server.process_available(sim);
        if (!keep_running)
            break;

        if (!server.connected()) {
            sim.cycles(1);
            ::usleep(1000);
        } else {
            sim.cycles(4);
        }
    }

    std::cout << "REMOTE_BITBANG_DONE connected=" << (server.ever_connected() ? 1 : 0)
              << " sim_time=" << main_time << std::endl;
    top.final();
    return 0;
}
