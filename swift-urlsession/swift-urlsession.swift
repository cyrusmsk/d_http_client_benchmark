import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@main
struct Main {
    static func main() async {
        let path = ProcessInfo.processInfo.environment["BENCH_PATH"] ?? "/ping"
        let count = Int(ProcessInfo.processInfo.environment["BENCH_COUNT"] ?? "5000") ?? 5000
        let concurrency = max(
            1,
            Int(ProcessInfo.processInfo.environment["BENCH_CONCURRENCY"] ?? "1") ?? 1
        )

        guard let url = URL(string: "http://127.0.0.1:8000" + path) else {
            print(0)
            return
        }

        let session = URLSession.shared
        var result = 0

        await withTaskGroup(of: Int.self) { group in
            for worker in 0..<min(concurrency, count) {
                group.addTask {
                    var workerResult = 0
                    var index = worker
                    while index < count {
                        do {
                            let (data, _) = try await session.data(from: url)
                            workerResult += data.count
                        } catch {
                            workerResult += 0
                        }
                        index += min(concurrency, count)
                    }
                    return workerResult
                }
            }

            for await value in group {
                result += value
            }
        }

        print(result)
    }
}