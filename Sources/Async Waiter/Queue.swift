public import Buffer
public import Buffer_Ring_Bounded_Primitive
public import Buffer_Ring_Primitive
public import Memory
public import Memory_Allocator
public import Memory_Allocator_Protocol
public import Queue
public import Storage

extension Queue::Queue where S: ~Copyable {

    @inlinable
    public mutating func popEligible<Outcome: Sendable, Metadata: ~Copyable & Sendable>(
        flaggedInto flagged:
            inout Queue::Queue<Async.Waiter.Queue.Flagged<Outcome, Metadata>>
    ) -> S.Element? where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Async.Waiter.Entry<Outcome, Metadata>>>.Ring {
        while !isEmpty {
            guard let entry = dequeue() else { break }
            guard let reason = entry.flag.reason else {
                return entry
            }
            flagged.enqueue(Async.Waiter.Queue.Flagged(reason: reason, entry: entry))
        }
        return nil
    }
}

extension Queue::Queue where S: ~Copyable {

    @inlinable
    public mutating func reapFlagged<Outcome: Sendable, Metadata: ~Copyable & Sendable>(
        into flagged: inout Queue::Queue<Async.Waiter.Queue.Flagged<Outcome, Metadata>>
    ) where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Async.Waiter.Entry<Outcome, Metadata>>>.Ring {
        var survivors = Queue::Queue<Async.Waiter.Entry<Outcome, Metadata>>()

        while !isEmpty {
            guard let entry = dequeue() else { break }
            if let reason = entry.flag.reason {
                flagged.enqueue(Async.Waiter.Queue.Flagged(reason: reason, entry: entry))
            } else {
                survivors.enqueue(entry)
            }
        }

        survivors.drain { entry in
            self.enqueue(entry)
        }
    }
}

extension Queue::Queue where S: ~Copyable {

    @inlinable
    public mutating func push<Outcome: Sendable, Metadata: ~Copyable & Sendable>(
        unchecked entry: consuming S.Element
    ) where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Async.Waiter.Entry<Outcome, Metadata>>>.Ring.Bounded {

        do {
            try enqueue(entry)
        } catch {
            preconditionFailure("Unchecked push requires spare capacity")
        }
    }
}

extension Queue::Queue where S: ~Copyable {

    @inlinable
    public mutating func popEligible<Outcome: Sendable, Metadata: ~Copyable & Sendable>(
        flaggedInto flagged:
            inout Queue::Queue<Async.Waiter.Queue.Flagged<Outcome, Metadata>>
    ) -> S.Element? where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Async.Waiter.Entry<Outcome, Metadata>>>.Ring.Bounded {
        while !isEmpty {
            guard let entry = dequeue() else { break }
            guard let reason = entry.flag.reason else {
                return entry
            }
            flagged.enqueue(Async.Waiter.Queue.Flagged(reason: reason, entry: entry))
        }
        return nil
    }
}

extension Queue::Queue where S: ~Copyable {

    @inlinable
    public mutating func reapFlagged<Outcome: Sendable, Metadata: ~Copyable & Sendable>(
        into flagged: inout Queue::Queue<Async.Waiter.Queue.Flagged<Outcome, Metadata>>
    ) where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Async.Waiter.Entry<Outcome, Metadata>>>.Ring.Bounded {
        var survivors = Queue::Queue<Async.Waiter.Entry<Outcome, Metadata>>()

        while !isEmpty {
            guard let entry = dequeue() else { break }
            if let reason = entry.flag.reason {
                flagged.enqueue(Async.Waiter.Queue.Flagged(reason: reason, entry: entry))
            } else {
                survivors.enqueue(entry)
            }
        }

        survivors.drain { entry in

            do {
                try self.enqueue(entry)
            } catch {
                preconditionFailure("Survivors fit within the original capacity")
            }
        }
    }
}
