import Foundation

@propertyWrapper
struct Atomic<ValueType> {
    let lock = NSLock()
    var value: ValueType

    init(wrappedValue value: ValueType) {
        self.value = value
    }

    var wrappedValue: ValueType {
        get {
            lock.lock()
            defer { lock.unlock() }
            return value
        }
        set {
            lock.lock()
            value = newValue
            lock.unlock()
        }
    }
}
