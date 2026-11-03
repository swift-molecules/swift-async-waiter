# swift-async-waiter

Use this package when you are building your own async synchronization primitive and need to park suspended callers in a FIFO queue, let them be cancelled or timed out from another context, and later resume each one exactly once. Start from `Async.Waiter.Entry`, which pairs a continuation with an `Async.Waiter.Flag`, and keep entries in `Async.Waiter.Queue.Unbounded` or `Async.Waiter.Queue.Bounded`. If you only need a finished primitive, use swift-async-semaphore, swift-async-channel or swift-async-barrier, which are built on this package.

## Laws

- An `Async.Waiter.Flag` only records; it never acts. Calling `cancel()` or `timeout()` does not resume the continuation or remove the entry from its queue. The entry stays where it is until `popEligible(flaggedInto:)` or `reapFlagged(into:)` reaches it.
- Flags are sticky and idempotent. Cancelled and timed-out are independent and can both be set, and neither can be cleared. `cancel()` and `timeout()` return `true` only for the call that sets the flag; repeat calls return `false`.
- When both flags are set, `reason` is `.cancelled`, whichever was set first.
- Flag reads and writes use relaxed atomics, so seeing a flag set does not order any other memory. Synchronise through the queue's owner.
- `popEligible(flaggedInto:)` dequeues from the front. It moves every flagged entry it meets into the flagged queue, in order, and returns the first unflagged entry. Entries behind that one are not inspected. It returns `nil` only once the queue is empty.
- `reapFlagged(into:)` scans the whole queue. Flagged entries move to the flagged queue, and unflagged entries stay in their original relative order. On a bounded queue it never fails, because the survivors always fit in the original capacity.
- An `Async.Waiter.Queue.Flagged` records its reason when it is removed from the queue. Setting the other flag afterwards does not change that reason.
- Neither queue operation resumes anything. The caller resumes flagged entries through `resumption(resolving:)`, which turns the reason into an outcome. It resumes eligible entries through `resumption(with:)`. Each builds an `Async.Waiter.Resumption` that does not run until `resume()` is called.
