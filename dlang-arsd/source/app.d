import std.stdio : writeln;
import arsd.http2;

void main()
{
	auto client = new HttpClient();
	client.keepAlive = true;
	foreach(_; 0..1000) {
		auto request = client.request(Uri("http://127.0.0.1:8000/get"));
		auto content = request.waitForCompletion();
		writeln(content.contentText);
	}
}
