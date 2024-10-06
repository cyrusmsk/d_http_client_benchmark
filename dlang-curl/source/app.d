import std.stdio : writeln;
import std.conv : to;
import std.net.curl;

void main()
{
	auto client = HTTP();
	int result;
	client.addRequestHeader("Connection", "keep-alive");
	foreach(_; 0..5_000) {
		auto response = get("http://127.0.0.1:8000/get", client);
		result += response.to!int;
	}
	writeln(result);
}
