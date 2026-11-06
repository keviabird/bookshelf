import Foundation

/// Пауза debounce, которая держит задачу, пока тест не вызовет `release()`.
/// `skipFirst` — первую паузу пропустить (чтобы получить первые результаты сразу).
/// После пробуждения проверяет отмену, как настоящий `Task.sleep`.
actor BlockingSleeper {
    private let gate = Gate()
    private var skipFirst: Bool
    private(set) var calls = 0

    init(skipFirst: Bool = false) {
        self.skipFirst = skipFirst
    }

    func sleep() async throws {
        calls += 1
        if skipFirst {
            skipFirst = false
        } else {
            await gate.wait()
        }
        try Task.checkCancellation()
    }

    func release() async {
        await gate.open()
    }
}

/// Даёт поработать уже запущенным задачам (например, отменённому запросу, который дождался ответа).
func drainTasks() async {
    for _ in 0..<50 { await Task.yield() }
}
