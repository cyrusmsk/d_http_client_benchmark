import std.stdio : writeln;
import std.process : environment;
import std.conv : to;
import vibe.core.core : runTask, Task;
import vibe.http.client;
import vibe.stream.operations;

void main()
{
    string path = environment.get("BENCH_PATH", "/ping");
    int count = to!int(environment.get("BENCH_COUNT", "5000"));
    int concurrency = to!int(environment.get("BENCH_CONCURRENCY", "1"));
    if (concurrency < 1)
        concurrency = 1;

    int result;
    immutable int workers = concurrency < count ? concurrency : count;
    Task[] tasks;

    foreach (workerNumber; 0 .. workers)
    {
        immutable int worker = workerNumber;
        tasks ~= runTask({
            void perform() nothrow
            {
                try
                {
                    for (int i = worker; i < count; i += workers)
                    {
                        requestHTTP(
                            "http://127.0.0.1:8000" ~ path,
                            (scope req) {
                                req.method = HTTPMethod.GET;
                            },
                            (scope res) {
                                result += cast(int)res.bodyReader.readAllUTF8.length;
                            }
                        );
                    }
                }
                catch (Exception e)
                {
                }
            }

            perform();
        });
    }

    foreach (task; tasks)
        task.join();

    writeln(result);
}
