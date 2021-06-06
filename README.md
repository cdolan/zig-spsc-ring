# zig-spsc-ring

A fast single-producer, single-consumer, wait-free ring buffer for the
Zig programming language.

## Usage

### Sharp Edges

To make enqueuing and dequeuing fast, the ring size must be a **power of two**
like 64, 256, 1024, 4096.

### Example

```zig
const std = @import("std");
const Ring = @import("./spsc_ring.zig").Ring;

pub fn main() anyerror!void {
    var buffer: [1024]u64 = undefined;
    var ring = Ring(u64).init(&buffer, buffer.len);

    if (ring.enqueue(1)) std.log.info("enqueued 1", .{});
    if (ring.enqueue(2)) std.log.info("enqueued 2", .{});
    if (ring.enqueue(3)) std.log.info("enqueued 3", .{});
    if (ring.enqueue(4)) std.log.info("enqueued 4", .{});

    if (ring.dequeue()) |n| std.log.info("dequeued {}", .{n}); // prints "info: dequeued 1"
    if (ring.dequeue()) |n| std.log.info("dequeued {}", .{n}); // prints "info: dequeued 2"
    if (ring.dequeue()) |n| std.log.info("dequeued {}", .{n}); // prints "info: dequeued 3"
    if (ring.dequeue()) |n| std.log.info("dequeued {}", .{n}); // prints "info: dequeued 4"

    if (ring.dequeue()) |n| std.log.info("dequeued {}", .{n}); // dequeue() returns null
}
```

## Zig

Tested on Zig 0.8.0.

- https://ziglang.org/
- https://github.com/ziglang/zig
- https://github.com/ziglang/zig/wiki/Community

## License
MIT
