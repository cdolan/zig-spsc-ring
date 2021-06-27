const std = @import("std");
const atomic = std.atomic;
const Atomic = std.atomic.Atomic;
const AtomicOrder = std.builtin.AtomicOrder;

pub fn Ring(comptime T: type) type {
    return struct {
        consumerHead: Atomic(usize) align(64),
        producerTail: Atomic(usize) align(64),
        buffer: [*]T,
        size: usize,
        mask: usize,

        const Self = @This();

        pub fn init(buffer: [*]T, size: usize) Self {
            return Self{
                .consumerHead = Atomic(usize).init(0),
                .producerTail = Atomic(usize).init(0),
                .buffer = buffer,
                .size = size,
                .mask = size - 1,
            };
        }

        pub fn enqueue(self: *Self, value: T) bool {
            const consumer = self.consumerHead.load(AtomicOrder.Acquire);
            const producer = self.producerTail.load(AtomicOrder.Unordered);
            const nextProducer = producer + 1;

            if (nextProducer & self.mask == consumer & self.mask) return false;

            self.buffer[producer & self.mask] = value;

            atomic.fence(AtomicOrder.Release);
            self.producerTail.store(nextProducer, AtomicOrder.Release);

            return true;
        }

        pub fn dequeue(self: *Self) ?T {
            const producer = self.producerTail.load(AtomicOrder.Acquire);
            const consumer = self.consumerHead.load(AtomicOrder.Unordered);

            if (consumer == producer) return null;

            atomic.fence(AtomicOrder.Acquire);

            const value = self.buffer[consumer & self.mask];

            atomic.fence(AtomicOrder.Release);
            self.consumerHead.store(consumer + 1, AtomicOrder.Release);

            return value;
        }

        pub fn length(self: *Self) usize {
            const consumer = self.consumerHead.load(AtomicOrder.Unordered);
            const producer = self.producerTail.load(AtomicOrder.Unordered);

            return (producer - consumer) & self.mask;
        }
    };
}

const expect = std.testing.expect;

test "enqueue" {
    var buffer = [4]i32{ 0, 0, 0, 0 };
    var ring = Ring(i32).init(&buffer, buffer.len);

    try expect(ring.enqueue(2) == true);
    try expect(ring.enqueue(3) == true);
    try expect(ring.enqueue(5) == true);
    try expect(ring.enqueue(7) == false);

    try expect(buffer[0] == 2);
    try expect(buffer[1] == 3);
    try expect(buffer[2] == 5);

    try expect(buffer[3] == 0);
}

test "dequeue" {
    var buffer: [4]i32 = undefined;
    var ring = Ring(i32).init(&buffer, buffer.len);

    _ = ring.enqueue(2);
    _ = ring.enqueue(3);
    _ = ring.enqueue(5);

    try expect(ring.dequeue().? == 2);
    try expect(ring.dequeue().? == 3);
    try expect(ring.dequeue().? == 5);

    try expect(ring.dequeue() == null);
}

test "length" {
    var buffer: [8]i32 = undefined;
    var ring = Ring(i32).init(&buffer, buffer.len);

    try expect(ring.length() == 0);

    _ = ring.enqueue(2);
    _ = ring.enqueue(3);
    _ = ring.enqueue(5);

    try expect(ring.length() == 3);

    _ = ring.dequeue();
    _ = ring.dequeue();
    _ = ring.dequeue();

    try expect(ring.length() == 0);
}
