import serverino;
import std.datetime: Duration, seconds;
import std.array: split;
import std.algorithm: startsWith;

mixin ServerinoMain;

@onServerInit ServerinoConfig configure()
{
    return ServerinoConfig
        .create()
        .setHttpTimeout(15.seconds)
        .enableKeepAlive(180.seconds)
        .addListener("0.0.0.0", 8000)
        .setWorkers(25);
}

@endpoint void hello(Request req, Output output) {
    if (req.uri == "/get" && req.method == Request.Method.Get)
        output ~= "1";
    else
        if (req.uri.startsWith("/user/") && req.method == Request.Method.Get)
            output ~= req.uri.split("/user/")[1];
}
