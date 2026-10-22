import serverino;
import std.datetime: Duration, seconds, msecs;
import std.array: split;
import std.string: indexOf, startsWith;
import std.conv: to;
import std.string: toLower;
import core.thread: Thread;

mixin ServerinoMain;

@onServerInit ServerinoConfig configure()
{
    return ServerinoConfig
        .create()
        .setHttpTimeout(15.seconds)
        .enableKeepAlive(180.seconds)
        .addListener("0.0.0.0", 8000)
        .setWorkers(10);
}

private size_t queryValue(Request req, string key, size_t defaultValue)
{
    if (req.get.has(key))
        return (req.get.read(key, defaultValue.to!string)).to!size_t;
    return defaultValue;
}

@endpoint void hello(Request req, Output output)
{
    if (req.path == "/ping")
    {
        output ~= "OK";
        return;
    }
    if (req.path == "/get")
    {
        output ~= "1";
        return;
    }
    if (req.path == "/json")
    {
        output ~= "{";
        output ~= "\"data\":\"" ~ repeat("a", 1013) ~ "\"";
        output ~= "}";
        return;
    }
    if (req.path == "/download")
    {
        auto chunk = repeat("a", 64 * 1024);
        output ~= chunk;
        return;
    }
    if (req.path == "/large")
    {
        auto chunk = repeat("a", queryValue(req, "size", 1024 * 1024));
        output ~= chunk;
        return;
    }
    if (req.path.startsWith("/delay"))
    {
        size_t ms = queryValue(req, "ms", 10);
        Thread.sleep(ms.msecs);
        output ~= "OK";
        return;
    }
    if (req.path == "/echo" && req.method == Request.Method.Post)
    {
        auto body = req.body;
        output ~= body.data;
        return;
    }
    if (req.path == "/status/404")
    {
        output.status = 404;
        output ~= "not found";
        return;
    }
    if (req.path == "/status/500")
    {
        output.status = 500;
        output ~= "server error";
        return;
    }
    output.status = 404;
    output ~= "not found";
}

private string repeat(string value, size_t count)
{
    string result;
    result.reserve(value.length * count);
    foreach (_; 0 .. count)
        result ~= value;
    return result;
}
