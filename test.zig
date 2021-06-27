const std = @import("std");
const Ring = @import("./spsc_ring.zig").Ring;

var buffer: [1024]u64 = undefined;
var ring: Ring(u64) = undefined;

pub fn producer() void {
    var counter: u64 = 1;
    var stalled: u64 = 0;

    while (stalled < 100_000) {
        if (ring.enqueue(counter)) {
            counter += 1;
        } else {
            stalled += 1;
        }
    }
}

pub fn consumer() void {
    var counter: u64 = 1;
    var starved: u64 = 0;

    while (starved < 100_000) {
        if ((ring.dequeue()) {
            counter += 1;
        } else {
            stalled += 1;
        }
    }
}

pub fn main() anyerror!void {
    ring = Ring(u64).init(&buffer, buffer.len);

    if (ring.dequeue()) |n| std.log.info("dequeued {}", .{n}); // prints "info: dequeued 1"
    if (ring.dequeue()) |n| std.log.info("dequeued {}", .{n}); // prints "info: dequeued 2"
    if (ring.dequeue()) |n| std.log.info("dequeued {}", .{n}); // prints "info: dequeued 3"
    if (ring.dequeue()) |n| std.log.info("dequeued {}", .{n}); // prints "info: dequeued 4"

    if (ring.dequeue()) |n| std.log.info("dequeued {}", .{n}); // dequeue() returns null
}
