#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <string>
#include <thread>
#include <vector>

namespace {

int env_int(const char *name, int fallback)
{
    const char *value = std::getenv(name);
    if (!value || !*value)
        return fallback;
    try
    {
        return std::stoi(value);
    }
    catch (...)
    {
        return fallback;
    }
}

std::string to_lower(std::string value)
{
    std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c) {
        return static_cast<char>(std::tolower(c));
    });
    return value;
}

class HttpClient
{
public:
    ~HttpClient()
    {
        close();
    }

    int request(const std::string &path)
    {
        for (int attempt = 0; attempt < 3; ++attempt)
        {
            if (!connect())
                return 0;

            std::string request =
                "GET " + path + " HTTP/1.1\r\n"
                "Host: 127.0.0.1:8000\r\n"
                "Connection: keep-alive\r\n"
                "\r\n";

            if (!send_all(request))
            {
                reconnect();
                continue;
            }

            std::string headers;
            std::string body;
            if (!read_response(headers, body))
            {
                reconnect();
                continue;
            }

            size_t content_length = content_length_of(headers);
            if (content_length == std::string::npos)
            {
                reconnect();
                continue;
            }

            return static_cast<int>(content_length);
        }
        return 0;
    }

private:
    int sock_ = -1;
    std::string pending_;
    size_t bodyNeeded = 0;

    static size_t content_length_of(const std::string &headers)
    {
        std::string lower = to_lower(headers);
        size_t pos = lower.find("content-length:");
        if (pos == std::string::npos)
            return std::string::npos;

        size_t start = lower.find(':', pos) + 1;
        size_t end = lower.find("\r\n", start);
        if (end == std::string::npos)
            return std::string::npos;

        return static_cast<size_t>(std::stoul(headers.substr(start, end - start)));
    }

    void close()
    {
        if (sock_ >= 0)
            ::close(sock_);
        sock_ = -1;
        pending_.clear();
    }

    void reconnect()
    {
        close();
    }

    bool connect()
    {
        if (sock_ >= 0)
            return true;

        sock_ = socket(AF_INET, SOCK_STREAM, 0);
        if (sock_ < 0)
            return false;

        sockaddr_in addr{};
        addr.sin_family = AF_INET;
        addr.sin_port = htons(8000);
        inet_pton(AF_INET, "127.0.0.1", &addr.sin_addr);

        if (::connect(sock_, reinterpret_cast<sockaddr *>(&addr), sizeof(addr)) < 0)
        {
            close();
            return false;
        }
        return true;
    }

    bool send_all(const std::string &data)
    {
        size_t sent = 0;
        while (sent < data.size())
        {
            ssize_t n = ::send(sock_, data.data() + sent, data.size() - sent, 0);
            if (n < 0)
                return false;
            sent += static_cast<size_t>(n);
        }
        return true;
    }

    bool read_some()
    {
        char buffer[1024];
        ssize_t n = ::recv(sock_, buffer, sizeof(buffer), 0);
        if (n <= 0)
            return false;
        pending_.append(buffer, static_cast<size_t>(n));
        return true;
    }

    bool read_headers(std::string &headers)
    {
        while (pending_.find("\r\n\r\n") == std::string::npos)
        {
            if (!read_some())
                return false;
        }

        size_t end = pending_.find("\r\n\r\n");
        headers = pending_.substr(0, end);
        pending_.erase(0, end + 4);
        return true;
    }

    bool read_body(std::string &body)
    {
        while (pending_.size() < bodyNeeded)
        {
            if (!read_some())
                return false;
        }
        body = pending_.substr(0, bodyNeeded);
        pending_.erase(0, bodyNeeded);
        return true;
    }

    bool read_response(std::string &headers, std::string &body)
    {
        if (!read_headers(headers))
            return false;
        size_t content_length = content_length_of(headers);
        if (content_length == std::string::npos)
            return false;
        bodyNeeded = content_length;
        return read_body(body);
    }
};

} // namespace

int main()
{
    std::string path = std::getenv("BENCH_PATH") ? std::getenv("BENCH_PATH") : "/ping";
    int total = env_int("BENCH_COUNT", 5000);
    int concurrency = env_int("BENCH_CONCURRENCY", 1);
    if (concurrency < 1)
        concurrency = 1;
    if (total < 1)
        total = 1;

    int workers = std::min(concurrency, total);
    std::vector<int> results(workers, 0);
    std::vector<std::thread> threads;
    threads.reserve(static_cast<size_t>(workers));

    for (int worker = 0; worker < workers; ++worker)
    {
        threads.emplace_back([&, worker]() {
            HttpClient client;
            int result = 0;
            for (int i = worker; i < total; i += workers)
                result += client.request(path);
            results[static_cast<size_t>(worker)] = result;
        });
    }

    for (auto &thread : threads)
        thread.join();

    long result = 0;
    for (int value : results)
        result += value;

    std::cout << result << std::endl;
    return 0;
}
