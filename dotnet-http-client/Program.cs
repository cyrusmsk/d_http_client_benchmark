using System;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;

namespace ConsoleApplication
{
    public class Program
    {
        private static readonly HttpClient client;

        static Program()
        {
            int initial = maxConcurrency();
            var handler = new SocketsHttpHandler
            {
                MaxConnectionsPerServer = initial,
                PooledConnectionLifetime = TimeSpan.FromMinutes(2)
            };
            client = new HttpClient(handler);
        }

        private static int maxConcurrency()
        {
            if (int.TryParse(Environment.GetEnvironmentVariable("BENCH_CONCURRENCY"), out int value))
                return Math.Max(1, value);
            return 1;
        }

        private static async Task<int> FetchAsync(string url)
        {
            var response = await client.GetAsync(url);
            var bytes = await response.Content.ReadAsByteArrayAsync();
            return bytes.Length;
        }

        public static async Task Main(string[] args)
        {
            string path = Environment.GetEnvironmentVariable("BENCH_PATH") ?? "/ping";
            if (!path.StartsWith("/")) path = "/" + path;
            string url = "http://127.0.0.1:8000" + path;
            int count = int.TryParse(Environment.GetEnvironmentVariable("BENCH_COUNT"), out var c) ? c : 5000;
            var semaphore = new System.Threading.SemaphoreSlim(maxConcurrency());

            var tasks = Enumerable.Range(0, count).Select(async _ =>
            {
                await semaphore.WaitAsync();
                try
                {
                    return await FetchAsync(url);
                }
                finally
                {
                    semaphore.Release();
                }
            });

            long result = (await Task.WhenAll(tasks)).Sum();
            Console.WriteLine(result);
        }
    }
}
