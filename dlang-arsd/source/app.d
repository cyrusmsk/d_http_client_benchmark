import std.stdio : writeln;
import arsd.http2;
import std.conv : to;

void main()
{
	auto client = new HttpClient();
	client.keepAlive = true;
	int result;
    HttpRequest[5_000] requests;
    HttpResponse response;

	foreach (i; 0 .. 5_000)
	{
		requests[i] = client.request(Uri("http://127.0.0.1:8000/get"));
        requests[i].send();
    }
    foreach (i; 0 .. 5_000)
    {
		response = requests[i].waitForCompletion();
		result += response.contentText.to!int;
	}
	writeln(result);
}
