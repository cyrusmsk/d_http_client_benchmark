import std.stdio : writeln;
import std.conv : to;
import vibe.http.client;
import vibe.stream.operations;

void main()
{
	int result;
	foreach(_; 0..5_000) {
		requestHTTP("http://127.0.0.1:8000/get",
			(scope req) {
				req.method = HTTPMethod.GET;
			},
			(scope res) {
				result += res.bodyReader.readAllUTF8.to!int;
			}	
		);
	}
	writeln(result);
}
