import std.stdio : writeln;
import std.range : iota;
import std.process : environment;
import std.conv : to;
import std.algorithm.iteration : map, sum;
import requests;

void main()
{
    string path = environment.get("BENCH_PATH", "/ping");
    int count = to!int(environment.get("BENCH_COUNT", "5000"));
    uint concurrency = to!uint(environment.get("BENCH_CONCURRENCY", "1"));
    if (concurrency < 1)
        concurrency = 1;

    int result = iota(count)
        .map!(n => Job("http://127.0.0.1:8000" ~ path))
        .pool(concurrency)
        .map!(r => cast(int)r.data.length)
        .sum;
    writeln(result);
}
