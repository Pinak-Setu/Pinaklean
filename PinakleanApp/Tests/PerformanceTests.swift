import XCTest
import Quick
import Nimble
@testable import PinakleanCore

class PerformanceTests: QuickSpec {
    override func spec() {
        describe("Performance") {
            it("should complete basic test") {
                expect(true).to(beTrue())
            }
        }
    }
}
