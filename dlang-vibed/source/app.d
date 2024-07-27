import std.stdio : writeln;
import vibe.http.client;
import vibe.stream.operations;

void main()
{
	foreach(_; 0..1000) {
		requestHTTP("http://127.0.0.1:8000/get",
			(scope req) {
				req.method = HTTPMethod.GET;
			},
			(scope res) {
				writeln(res.bodyReader.readAllUTF8());
			}	
		);
	}
}
