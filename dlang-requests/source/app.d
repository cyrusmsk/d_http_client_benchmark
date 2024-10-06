import std.stdio : writeln;
import std.range : iota;
import std.conv : to;
import std.algorithm : map, sum;
import requests;

void main()
{
	int result = iota(5_000)
        .map!(n => Job("http://127.0.0.1:8000/get"))
		.pool(10)
		.map!(r => r.data[0] - cast(ubyte)'0')
		.sum;
	writeln(result);
}
