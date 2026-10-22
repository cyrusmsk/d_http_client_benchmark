import std.stdio : writeln;
import arsd.http2;
import std.process : environment;
import std.conv : to;

void main()
{
    auto client = new HttpClient();
    client.keepAlive = true;
    string path = environment.get("BENCH_PATH", "/ping");
    int count = to!int(environment.get("BENCH_COUNT", "5000"));
    int concurrency = to!int(environment.get("BENCH_CONCURRENCY", "1"));
    if (concurrency < 1)
        concurrency = 1;

    int result;
    HttpRequest[] requests = new HttpRequest[concurrency];
    HttpResponse[] responses = new HttpResponse[concurrency];
    int in_flight = 0;

    foreach (i; 0 .. count)
    {
        requests[in_flight] = client.request(Uri("http://127.0.0.1:8000" ~ path));
        requests[in_flight].send();
        in_flight++;

        if (in_flight == concurrency)
        {
            foreach (j; 0 .. concurrency)
            {
                responses[j] = requests[j].waitForCompletion();
                result += cast(int)responses[j].contentText.length;
            }
            in_flight = 0;
        }
    }

    if (in_flight > 0)
    {
        foreach (j; 0 .. in_flight)
        {
            responses[j] = requests[j].waitForCompletion();
            result += cast(int)responses[j].contentText.length;
        }
    }

    writeln(result);
}
