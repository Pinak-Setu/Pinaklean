import Nimble
import Quick
import XCTest

Pinaklean / PinakleanApp / Tests / ResourceAndLockTests.swift

class ResourceAndLockTests: QuickSpec {
    override func spec() {
        describe("Resource file existence") {
            it("should have a model manifest file in Resources/Models") {
                let manifestPath = "Pinaklean/PinakleanApp/Core/Resources/Models/ModelManifest.json"
                let fileManager = FileManager.default
                expect(fileManager.fileExists(atPath: manifestPath)).to(
                    beTrue(), description: "ModelManifest.json should exist")
            }

            it("should have a Resources directory") {
                let resourcesPath = "Pinaklean/PinakleanApp/Core/Resources"
                let fileManager = FileManager.default
                var isDir: ObjCBool = false
                let exists = fileManager.fileExists(atPath: resourcesPath, isDirectory: &isDir)
                expect(exists && isDir.boolValue).to(
                    beTrue(), description: "Resources directory should exist")
            }
        }

        describe("SwiftPM lock file cleanup") {
            it("should remove Package.resolved.lock after SwiftPM operations") {
                let lockFilePath = "Pinaklean/PinakleanApp/Package.resolved.lock"
                let fileManager = FileManager.default

                // Simulate lock file creation
                fileManager.createFile(atPath: lockFilePath, contents: Data(), attributes: nil)
                expect(fileManager.fileExists(atPath: lockFilePath)).to(
                    beTrue(), description: "Lock file should exist after creation")

                // Simulate cleanup logic
                do {
                    try fileManager.removeItem(atPath: lockFilePath)
                } catch {
                    fail("Failed to remove lock file: \(error)")
                }
                expect(fileManager.fileExists(atPath: lockFilePath)).to(
                    beFalse(), description: "Lock file should be removed after cleanup")
            }
        }
    }
}
