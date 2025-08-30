import ArgumentParser
import XCTest

@testable import PinakleanCLI

Pinaklean / PinakleanApp / Tests / CLITests.swift

final class CLITests: XCTestCase {

    func testHelpArgument() {
        // Simulate running the CLI with --help
        let arguments = ["pinaklean", "--help"]
        let output = runCLI(arguments: arguments)
        XCTAssertTrue(output.contains("USAGE"), "Help output should contain usage information")
        XCTAssertTrue(output.contains("pinaklean"), "Help output should mention the command name")
    }

    func testVersionArgument() {
        // Simulate running the CLI with --version
        let arguments = ["pinaklean", "--version"]
        let output = runCLI(arguments: arguments)
        XCTAssertTrue(
            output.lowercased().contains("version"), "Version output should mention version")
    }

    func testScanCommand() {
        // Simulate running the CLI with scan command
        let arguments = ["pinaklean", "scan", "--dry-run"]
        let output = runCLI(arguments: arguments)
        XCTAssertTrue(
            output.contains("Scan Complete") || output.contains("No items found"),
            "Scan command should complete and output results")
    }

    func testCleanCommand() {
        // Simulate running the CLI with clean command
        let arguments = ["pinaklean", "clean", "--dry-run"]
        let output = runCLI(arguments: arguments)
        XCTAssertTrue(
            output.contains("Clean Complete") || output.contains("No items cleaned"),
            "Clean command should complete and output results")
    }

    // Helper to simulate CLI execution and capture output
    private func runCLI(arguments: [String]) -> String {
        // Redirect stdout and stderr to capture output
        let pipe = Pipe()
        let originalStdout = dup(STDOUT_FILENO)
        let originalStderr = dup(STDERR_FILENO)
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)

        // Run the CLI main entry point
        var output = ""
        do {
            try PinakleanCLI.main(arguments)
        } catch {
            // Ignore errors for test purposes
        }

        // Restore stdout and stderr
        pipe.fileHandleForWriting.closeFile()
        dup2(originalStdout, STDOUT_FILENO)
        dup2(originalStderr, STDERR_FILENO)

        // Read output from the pipe
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let str = String(data: data, encoding: .utf8) {
            output = str
        }
        return output
    }
}
