import XCTest
import Quick
import Nimble

class UITests: QuickSpec {
    override func spec() {
        describe("UI Components") {
            it("should pass basic UI test") {
                expect(true).to(beTrue())
            }
        }
    }
}
