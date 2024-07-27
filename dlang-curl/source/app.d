import std.stdio : writeln;
import std.net.curl;

void main()
{
	auto client = HTTP();
	client.addRequestHeader("Connection", "keep-alive");
	foreach(_; 0..1000) {
		auto content = get("http://127.0.0.1:8000/get", client);
		writeln(content);
	}
}
