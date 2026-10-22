const std = @import("std");
const http = std.http;

fn envSlice(name: [*:0]const u8, default: []const u8) []const u8 {
    const ptr = std.c.getenv(name) orelse return default;
    return std.mem.span(ptr);
}

fn envUsize(name: [*:0]const u8, default: usize) usize {
    const ptr = std.c.getenv(name) orelse return default;
    const text = std.mem.span(ptr);
    return std.fmt.parseInt(usize, text, 10) catch default;
}

fn worker(io: std.Io, uri: std.Uri, total: usize, stride: usize, worker_index: usize, result_ptr: *usize) void {
    var client: http.Client = .{ .io = io, .allocator = std.heap.page_allocator };
    var result: usize = 0;
    var index = worker_index;

    while (index < total) {
        var request = client.request(
            .GET,
            uri,
            .{ .keep_alive = true },
        ) catch break;
        defer request.deinit();

        request.sendBodiless() catch break;

        var redirect_buffer: [8 * 1024]u8 = undefined;
        var response = request.receiveHead(&redirect_buffer) catch break;

        var transfer_buffer: [64 * 1024]u8 = undefined;
        var reader = response.reader(&transfer_buffer);
        var body_length: usize = 0;
        var chunk: [64 * 1024]u8 = undefined;

        while (reader.readSliceShort(&chunk)) |bytes_read| {
            if (bytes_read == 0)
                break;
            body_length += bytes_read;
        } else |_| {
            break;
        }

        result += body_length;
        index += stride;
    }

    result_ptr.* = result;
}

pub fn main() !void {
    const path = envSlice("BENCH_PATH", "/ping");
    const total = envUsize("BENCH_COUNT", 5000);
    const concurrency = envUsize("BENCH_CONCURRENCY", 1);

    if (total == 0)
        return;
    if (concurrency == 0)
        @panic("BENCH_CONCURRENCY must be greater than zero");

    const workers = if (concurrency < total) concurrency else total;

    var url_buffer: [512]u8 = undefined;
    const url = try std.fmt.bufPrintSentinel(&url_buffer, "http://127.0.0.1:8000{s}", .{path}, 0);
    const uri = try std.Uri.parse(url);

    var threaded = std.Io.Threaded.init(std.heap.page_allocator, .{});
    const io = threaded.io();

    const results = try std.heap.page_allocator.alloc(usize, workers);
    defer std.heap.page_allocator.free(results);
    @memset(results, 0);

    const threads = try std.heap.page_allocator.alloc(std.Thread, workers);
    defer std.heap.page_allocator.free(threads);

    for (threads, 0..) |*thread, worker_index| {
        thread.* = try std.Thread.spawn(.{}, worker, .{ io, uri, total, workers, worker_index, &results[worker_index] });
    }

    for (threads) |thread|
        thread.join();

    var total_result: usize = 0;
    for (results) |value|
        total_result += value;

    std.debug.print("{d}\n", .{total_result});
}
