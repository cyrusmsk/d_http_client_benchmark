import std.stdio : writeln;
import arsd.http2;
import std.conv : to;

void main()
{
	auto client = new HttpClient();
	client.keepAlive = true;
	int result;
	foreach (_; 0 .. 5_000)
	{
		auto request = client.request(Uri("http://127.0.0.1:8000/get"));
		auto response = request.waitForCompletion();
		result += response.contentText.to!int;
	}
	writeln(result);
}
