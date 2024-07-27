import std.stdio : writeln;
import requests;

void main()
{
	foreach (_; 0..1000)
	{
		auto content = getContent("http://127.0.0.1:8000/get");
		writeln(content);
	}
}
