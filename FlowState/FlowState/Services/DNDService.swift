import Foundation

@Observable
final class DNDService {
    var isDNDEnabled: Bool = false

    func checkStatus() {
        // Mocked — real implementation would use Focus/DND APIs
        isDNDEnabled = false
    }

    func toggleDND() {
        isDNDEnabled.toggle()
    }
}
