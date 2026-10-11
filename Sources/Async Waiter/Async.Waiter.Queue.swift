import Buffer
public import Buffer_Ring_Bounded_Primitive
import Buffer_Ring_Primitive
import Buffer_Linear_Primitive
import Buffer_Linear_Bounded_Primitive
import Memory_Allocator_Pool
import Memory_Pool
import Memory_Allocator
import Memory
import Ownership_Shared_Primitive
import Store
public import Queue
public import Storage

extension Async.Waiter {

    public enum Queue {}
}

extension Async.Waiter.Queue {

    public typealias Bounded<Outcome: Sendable, Metadata: ~Copyable & Sendable> =
        Queue::Queue<Async.Waiter.Entry<Outcome, Metadata>>.Bounded

    public typealias Unbounded<Outcome: Sendable, Metadata: ~Copyable & Sendable> =
        Queue::Queue<Async.Waiter.Entry<Outcome, Metadata>>

    public typealias Drain<Element: ~Copyable> = Queue::Queue<Element>
}
