using System;
using System.Net.Http;

namespace ConsoleApplication
{
    public class Program
    {
        private static HttpClient client = new HttpClient();
        public static async Task Main(string[] args)
        {
            string baseUrl = "http://127.0.0.1:8000/get";
            var result = 0;
            {
                for(int i = 0; i < 5000; i++)
                {
                    var response = await client.GetAsync(baseUrl);
                    string content = await response.Content.ReadAsStringAsync();
                    result += Int32.Parse(content);
                }
            }
        Console.WriteLine(result);
        }
    }
}
