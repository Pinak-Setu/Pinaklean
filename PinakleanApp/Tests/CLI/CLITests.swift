
import XCTest

class CLITests: XCTestCase {

    func testScanJsonOutputIsValidJson() throws {
        // Gate by env to avoid flaky integration in unit test runs
        let env = ProcessInfo.processInfo.environment
        guard env["PINAKLEAN_CLI_E2E"] == "1" else {
            throw XCTSkip("Skipping CLI JSON test (set PINAKLEAN_CLI_E2E=1 to enable)")
        }

        let expectation = XCTestExpectation(description: "scan --json should produce valid JSON")

        let cliPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".build/release/pinaklean-cli").path
        let process = Process()
        process.executableURL = URL(fileURLWithPath: cliPath)
        process.arguments = ["scan", "--json"]

        let pipe = Pipe()
        process.standardOutput = pipe

        process.terminationHandler = { _ in
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                print("CLI Output:\n\(output)")
            }
            do {
                _ = try JSONSerialization.jsonObject(with: data, options: [])
                expectation.fulfill()
            } catch {
                XCTFail("Failed to parse JSON: \(error)")
            }
        }

        try process.run()
        wait(for: [expectation], timeout: 10.0)
    }

}
