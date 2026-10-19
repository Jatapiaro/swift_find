actor AsyncQueue {
  typealias Job<T: Sendable> = @Sendable () async throws -> T
  var maxWorkers: Int = 4
  var currentJobs: Int = 0
  var pending: [() async -> Void] = [() async -> Void]()

  init(maxWorkers: Int = 4) {
    self.maxWorkers = maxWorkers
  }

  func enqueue<T: Sendable>(job: @escaping Job<T>) async throws -> T {
    return try await withCheckedThrowingContinuation {
      (continuation: CheckedContinuation<T, Error>) in
      pending.append {
        do {
          continuation.resume(returning: try await job())
        } catch {
          continuation.resume(throwing: error)
        }
      }
      executeJobs()
    }
  }

  private func executeJobs() {
    while currentJobs < maxWorkers {
      guard let job: (() async -> Void) = getNext() else {
        break
      }

      currentJobs += 1
      Task {
        await job()
        await finishJob()
      }
    }
  }

  private func finishJob() async {
    currentJobs -= 1
    executeJobs()
  }

  private func getNext() -> (() async -> Void)? {
    pending.isEmpty ? nil : pending.removeFirst()
  }
}
