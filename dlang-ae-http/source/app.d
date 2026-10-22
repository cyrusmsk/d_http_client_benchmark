import core.time : seconds;
import std.conv : to;
import std.process : environment;
import std.stdio : writeln;

import ae.net.asockets;
import ae.net.http.client : HttpClient;
import ae.net.http.common : HttpRequest, HttpResponse;
import ae.sys.dataset : joinData;

int main()
{
    string path = environment.get("BENCH_PATH", "/ping");
    size_t total = to!size_t(environment.get("BENCH_COUNT", "5000"));
    size_t concurrency = to!size_t(environment.get("BENCH_CONCURRENCY", "1"));
    if (concurrency == 0)
        concurrency = 1;
    if (total == 0)
        total = 1;
    size_t maxActive = concurrency < total ? concurrency : total;

    string url = "http://127.0.0.1:8000" ~ path;
    size_t result = 0;
    HttpClient[] active;

    for (size_t started = 0; started < total; started += maxActive)
    {
        size_t batch = maxActive < total - started ? maxActive : total - started;

        foreach (_; 0 .. batch)
        {
            auto client = new HttpClient(30.seconds);
            active ~= client;
            client.keepAlive = false;
            client.agent = "dlang-ae-http";

            client.handleResponse = (HttpResponse response, string disconnectReason)
            {
                result += cast(size_t)joinData(response.data).length;
                
            };
            client.handleDisconnect = (string reason, DisconnectType type) {};

            auto request = new HttpRequest;
            request.method = "GET";
            request.resource = url;
            client.request(request);
        }

        socketManager.loop();
    }

    writeln(result);
    return 0;
}
