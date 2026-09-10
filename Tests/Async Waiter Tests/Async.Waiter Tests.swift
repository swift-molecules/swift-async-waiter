import Async_Waiter
import Async
import Testing

enum Waiter {
    enum Test {
        @Suite struct `Waiter flags record cancellation and timeout` {}
        @Suite struct `Waiter entries preserve their signals and lifetimes` {}
        @Suite struct `Waiter queues preserve insertion and removal` {}
    }
}

extension Waiter.Test.`Waiter flags record cancellation and timeout` {
    @Test
    func `Init creates unflagged state`() {
        let flag = Async.Waiter.Flag()
        #expect(!flag.cancelled)
        #expect(!flag.timedOut)
        #expect(!flag.isFlagged)
        #expect(flag.reason == nil)
    }

    @Test
    func `Cancel sets cancelled flag`() {
        let flag = Async.Waiter.Flag()
        let didSet = flag.cancel()
        #expect(didSet)
        #expect(flag.cancelled)
        #expect(flag.isFlagged)
    }

    @Test
    func `Cancel returns false on second call`() {
        let flag = Async.Waiter.Flag()
        #expect(flag.cancel())
        #expect(!flag.cancel())
    }

    @Test
    func `Timeout sets timedOut flag`() {
        let flag = Async.Waiter.Flag()
        let didSet = flag.timeout()
        #expect(didSet)
        #expect(flag.timedOut)
        #expect(flag.isFlagged)
    }

    @Test
    func `Timeout returns false on second call`() {
        let flag = Async.Waiter.Flag()
        #expect(flag.timeout())
        #expect(!flag.timeout())
    }

    @Test
    func `Cancel and timeout are independent`() {
        let flag = Async.Waiter.Flag()
        #expect(flag.cancel())
        #expect(flag.timeout())
        #expect(flag.cancelled)
        #expect(flag.timedOut)
    }

    @Test
    func `Reason returns cancelled when only cancelled`() {
        let flag = Async.Waiter.Flag()
        flag.cancel()
        #expect(flag.reason == .cancelled)
    }

    @Test
    func `Reason returns timedOut when only timedOut`() {
        let flag = Async.Waiter.Flag()
        flag.timeout()
        #expect(flag.reason == .timedOut)
    }

    @Test
    func `Reason prefers cancelled over timedOut`() {
        let flag = Async.Waiter.Flag()
        flag.cancel()
        flag.timeout()
        #expect(flag.reason == .cancelled)
    }

    @Test
    func `Reason prefers cancelled regardless of set order`() {
        let flag = Async.Waiter.Flag()
        flag.timeout()
        flag.cancel()
        #expect(flag.reason == .cancelled)
    }

    @Test
    func `Reason returns nil when unflagged`() {
        let flag = Async.Waiter.Flag()
        #expect(flag.reason == nil)
    }
}

extension Waiter.Test.`Waiter entries preserve their signals and lifetimes` {
    @Test
    func `Entry stores flag reference`() {
        let flag = Async.Waiter.Flag()
        let cont = Async.Continuation<Int> { _ in }
        let entry = Async.Waiter.Entry(continuation: cont, flag: flag)
        let isFlagged = entry.flag.isFlagged
        #expect(!isFlagged)

        flag.cancel()
        let nowCancelled = entry.flag.cancelled
        #expect(nowCancelled)
        _ = consume entry
    }

    @Test
    func `Entry convenience init without metadata`() {
        let flag = Async.Waiter.Flag()
        let cont = Async.Continuation<Bool> { _ in }
        let entry = Async.Waiter.Entry(continuation: cont, flag: flag)
        let isFlagged = entry.flag.isFlagged
        #expect(!isFlagged)
        _ = consume entry
    }

    @Test
    func `Resumption resumes continuation with outcome`() {
        let publication = Async.Publication<Int>()
        let flag = Async.Waiter.Flag()
        let cont = Async.Continuation<Int> { value in
            publication.publish(value)
        }
        let entry = Async.Waiter.Entry(continuation: cont, flag: flag)
        let resumption = entry.resumption(with: 99)
        resumption.resume()
        #expect(publication.take() == 99)
    }

    @Test
    func `Resumption with different outcome types`() {
        let publication = Async.Publication<Bool>()
        let flag = Async.Waiter.Flag()
        let cont = Async.Continuation<Bool> { value in
            publication.publish(value)
        }
        let entry = Async.Waiter.Entry(continuation: cont, flag: flag)
        entry.resumption(with: true).resume()
        #expect(publication.take() == true)
    }
}

extension Waiter.Test.`Waiter queues preserve insertion and removal` {
    @Test
    func `PopEligible returns unflagged entry`() {
        var queue = Async.Waiter.Queue.Unbounded<Bool, Void>()

        let flag = Async.Waiter.Flag()
        queue.enqueue(
            Async.Waiter.Entry(
                continuation: Async.Continuation<Bool> { _ in },
                flag: flag
            )
        )

        var flagged = Async.Waiter.Queue.Drain<Async.Waiter.Queue.Flagged<Bool, Void>>()
        if let eligible = queue.popEligible(flaggedInto: &flagged) {
            let isFlagged = eligible.flag.isFlagged
            #expect(!isFlagged)
            _ = consume eligible
        } else {
            Issue.record("Expected an eligible entry")
        }
    }

    @Test
    func `PopEligible skips cancelled entries`() {
        var queue = Async.Waiter.Queue.Unbounded<Bool, Void>()

        let flag1 = Async.Waiter.Flag()
        flag1.cancel()
        queue.enqueue(
            Async.Waiter.Entry(
                continuation: Async.Continuation<Bool> { _ in },
                flag: flag1
            )
        )

        let flag2 = Async.Waiter.Flag()
        queue.enqueue(
            Async.Waiter.Entry(
                continuation: Async.Continuation<Bool> { _ in },
                flag: flag2
            )
        )

        var flagged = Async.Waiter.Queue.Drain<Async.Waiter.Queue.Flagged<Bool, Void>>()
        if let eligible = queue.popEligible(flaggedInto: &flagged) {
            let isFlagged = eligible.flag.isFlagged
            #expect(!isFlagged)
            _ = consume eligible
        } else {
            Issue.record("Expected an eligible entry")
        }

        var flaggedCount = 0
        while !flagged.isEmpty {
            _ = flagged.dequeue()
            flaggedCount += 1
        }
        #expect(flaggedCount == 1)
    }

    @Test
    func `PopEligible skips timed out entries`() {
        var queue = Async.Waiter.Queue.Unbounded<Bool, Void>()

        let flag1 = Async.Waiter.Flag()
        flag1.timeout()
        queue.enqueue(
            Async.Waiter.Entry(
                continuation: Async.Continuation<Bool> { _ in },
                flag: flag1
            )
        )

        let flag2 = Async.Waiter.Flag()
        queue.enqueue(
            Async.Waiter.Entry(
                continuation: Async.Continuation<Bool> { _ in },
                flag: flag2
            )
        )

        var flagged = Async.Waiter.Queue.Drain<Async.Waiter.Queue.Flagged<Bool, Void>>()
        if let eligible = queue.popEligible(flaggedInto: &flagged) {
            let isFlagged = eligible.flag.isFlagged
            #expect(!isFlagged)
            _ = consume eligible
        } else {
            Issue.record("Expected an eligible entry")
        }

        var flaggedCount = 0
        while !flagged.isEmpty {
            _ = flagged.dequeue()
            flaggedCount += 1
        }
        #expect(flaggedCount == 1)
    }

    @Test
    func `PopEligible skips multiple flagged entries`() {
        var queue = Async.Waiter.Queue.Unbounded<Bool, Void>()

        let flag1 = Async.Waiter.Flag()
        flag1.cancel()
        queue.enqueue(
            Async.Waiter.Entry(
                continuation: Async.Continuation<Bool> { _ in },
                flag: flag1
            )
        )

        let flag2 = Async.Waiter.Flag()
        flag2.timeout()
        queue.enqueue(
            Async.Waiter.Entry(
                continuation: Async.Continuation<Bool> { _ in },
                flag: flag2
            )
        )

        let flag3 = Async.Waiter.Flag()
        queue.enqueue(
            Async.Waiter.Entry(
                continuation: Async.Continuation<Bool> { _ in },
                flag: flag3
            )
        )

        var flagged = Async.Waiter.Queue.Drain<Async.Waiter.Queue.Flagged<Bool, Void>>()
        if let eligible = queue.popEligible(flaggedInto: &flagged) {
            let isFlagged = eligible.flag.isFlagged
            #expect(!isFlagged)
            _ = consume eligible
        } else {
            Issue.record("Expected an eligible entry")
        }

        var flaggedCount = 0
        while !flagged.isEmpty {
            _ = flagged.dequeue()
            flaggedCount += 1
        }
        #expect(flaggedCount == 2)
    }

    @Test
    func `PopEligible returns nil when all flagged`() {
        var queue = Async.Waiter.Queue.Unbounded<Bool, Void>()

        let flag1 = Async.Waiter.Flag()
        flag1.cancel()
        queue.enqueue(
            Async.Waiter.Entry(
                continuation: Async.Continuation<Bool> { _ in },
                flag: flag1
            )
        )

        let flag2 = Async.Waiter.Flag()
        flag2.timeout()
        queue.enqueue(
            Async.Waiter.Entry(
                continuation: Async.Continuation<Bool> { _ in },
                flag: flag2
            )
        )

        var flagged = Async.Waiter.Queue.Drain<Async.Waiter.Queue.Flagged<Bool, Void>>()
        if let eligible = queue.popEligible(flaggedInto: &flagged) {
            Issue.record("Expected nil but got an eligible entry")
            _ = consume eligible
        }

        var flaggedCount = 0
        while !flagged.isEmpty {
            _ = flagged.dequeue()
            flaggedCount += 1
        }
        #expect(flaggedCount == 2)
    }

    @Test
    func `PopEligible returns nil from empty queue`() {
        var queue = Async.Waiter.Queue.Unbounded<Bool, Void>()
        var flagged = Async.Waiter.Queue.Drain<Async.Waiter.Queue.Flagged<Bool, Void>>()
        if let eligible = queue.popEligible(flaggedInto: &flagged) {
            Issue.record("Expected nil from empty queue")
            _ = consume eligible
        }
    }

    @Test
    func `ReapFlagged collects flagged and retains unflagged`() {
        var queue = Async.Waiter.Queue.Unbounded<Bool, Void>()

        queue.enqueue(
            Async.Waiter.Entry(
                continuation: Async.Continuation<Bool> { _ in },
                flag: Async.Waiter.Flag()
            )
        )

        let flagCancel = Async.Waiter.Flag()
        flagCancel.cancel()
        queue.enqueue(
            Async.Waiter.Entry(
                continuation: Async.Continuation<Bool> { _ in },
                flag: flagCancel
            )
        )

        queue.enqueue(
            Async.Waiter.Entry(
                continuation: Async.Continuation<Bool> { _ in },
                flag: Async.Waiter.Flag()
            )
        )

        let flagTimeout = Async.Waiter.Flag()
        flagTimeout.timeout()
        queue.enqueue(
            Async.Waiter.Entry(
                continuation: Async.Continuation<Bool> { _ in },
                flag: flagTimeout
            )
        )

        var flagged = Async.Waiter.Queue.Drain<Async.Waiter.Queue.Flagged<Bool, Void>>()
        queue.reapFlagged(into: &flagged)

        var flaggedCount = 0
        while !flagged.isEmpty {
            _ = flagged.dequeue()
            flaggedCount += 1
        }
        #expect(flaggedCount == 2)

        var remainingCount = 0
        while !queue.isEmpty {
            _ = queue.dequeue()
            remainingCount += 1
        }
        #expect(remainingCount == 2)
    }

    @Test
    func `ReapFlagged on empty queue produces no flagged entries`() {
        var queue = Async.Waiter.Queue.Unbounded<Bool, Void>()
        var flagged = Async.Waiter.Queue.Drain<Async.Waiter.Queue.Flagged<Bool, Void>>()
        queue.reapFlagged(into: &flagged)
        let isEmpty = flagged.isEmpty
        #expect(isEmpty)
    }

    @Test
    func `ReapFlagged with no flagged entries preserves all`() {
        var queue = Async.Waiter.Queue.Unbounded<Bool, Void>()

        queue.enqueue(
            Async.Waiter.Entry(
                continuation: Async.Continuation<Bool> { _ in },
                flag: Async.Waiter.Flag()
            )
        )
        queue.enqueue(
            Async.Waiter.Entry(
                continuation: Async.Continuation<Bool> { _ in },
                flag: Async.Waiter.Flag()
            )
        )

        var flagged = Async.Waiter.Queue.Drain<Async.Waiter.Queue.Flagged<Bool, Void>>()
        queue.reapFlagged(into: &flagged)

        let noFlagged = flagged.isEmpty
        #expect(noFlagged)

        var remainingCount = 0
        while !queue.isEmpty {
            _ = queue.dequeue()
            remainingCount += 1
        }
        #expect(remainingCount == 2)
    }

    @Test
    func `Flagged entry preserves cancel reason`() {
        var queue = Async.Waiter.Queue.Unbounded<Bool, Void>()

        let flag = Async.Waiter.Flag()
        flag.cancel()
        queue.enqueue(
            Async.Waiter.Entry(
                continuation: Async.Continuation<Bool> { _ in },
                flag: flag
            )
        )

        var flagged = Async.Waiter.Queue.Drain<Async.Waiter.Queue.Flagged<Bool, Void>>()
        _ = queue.popEligible(flaggedInto: &flagged)

        if let entry = flagged.dequeue() {
            let reason = entry.reason
            #expect(reason == .cancelled)
            _ = consume entry
        } else {
            Issue.record("Expected a flagged entry")
        }
    }

    @Test
    func `Flagged entry preserves timeout reason`() {
        var queue = Async.Waiter.Queue.Unbounded<Bool, Void>()

        let flag = Async.Waiter.Flag()
        flag.timeout()
        queue.enqueue(
            Async.Waiter.Entry(
                continuation: Async.Continuation<Bool> { _ in },
                flag: flag
            )
        )

        var flagged = Async.Waiter.Queue.Drain<Async.Waiter.Queue.Flagged<Bool, Void>>()
        _ = queue.popEligible(flaggedInto: &flagged)

        if let entry = flagged.dequeue() {
            let reason = entry.reason
            #expect(reason == .timedOut)
            _ = consume entry
        } else {
            Issue.record("Expected a flagged entry")
        }
    }

    @Test
    func `Flagged split deconstructs into components`() {
        let flag = Async.Waiter.Flag()
        flag.timeout()
        let entry = Async.Waiter.Entry(
            continuation: Async.Continuation<Bool> { _ in },
            flag: flag
        )
        let flaggedEntry = Async.Waiter.Queue.Flagged(reason: .timedOut, entry: entry)
        let split = flaggedEntry.split()
        let reason = split.reason
        let isTimedOut = split.entry.flag.timedOut
        #expect(reason == .timedOut)
        #expect(isTimedOut)
        _ = consume split
    }
}
