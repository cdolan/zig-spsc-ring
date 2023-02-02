# zig-spsc-ring

Fast single-producer single-consumer wait-free ring buffer for Zig.

## Usage

For efficient enqueuing and dequeuing, it is recommended that the ring size be
a power of two (i.e., 2^N), such as 8, 16, 32, 64, 256, 1024, 4096, etc...
If the size is not a power of two, a debug assertion will fail.

## Example

```zig
const std = @import("std");
const Ring = @import("spsc_ring.zig").Ring;

pub fn main() !void {
    var buf: [256]u64 = undefined;
    var ring = Ring(u64).init(buf[0..]);

    var producer_thread = try std.Thread.spawn(.{}, producer, .{&ring});
    var consumer_thread = try std.Thread.spawn(.{}, consumer, .{&ring});
    producer_thread.join();
    consumer_thread.join();
}

fn producer(ring: *Ring(u64)) void {
    _ = ring.enqueue(42); // true - success. false - full buffer.
}

fn consumer(ring: *Ring(u64)) !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    while (true) {
        if (ring.dequeue()) |answer| {
            try stdout.print("answer = {}\n", .{answer});
            try bw.flush();
            return;
        }
    }
}
```

## Zig

Tested on Zig 0.11.0-dev.1430+ce6de2df8

- https://ziglang.org/
- https://github.com/ziglang/zig
- https://github.com/ziglang/zig/wiki/Community

## License
MIT
