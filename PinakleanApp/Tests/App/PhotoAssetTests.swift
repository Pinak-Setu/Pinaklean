
import XCTest
import Quick
import Nimble
@testable import PinakleanCore

class PhotoAssetTests: QuickSpec {
    override func spec() {
        describe("PhotoAsset data model") {
            var photoAsset: PhotoAsset!
            let assetId = "test_asset_id"
            let creationDate = Date()
            let location = "/Users/test/photo.jpg"

            beforeEach {
                photoAsset = PhotoAsset(
                    id: assetId,
                    creationDate: creationDate,
                    location: location,
                    isFavorite: false,
                    isHidden: false,
                    fileSize: 1024 * 1024
                )
            }

            it("should correctly initialize its properties") {
                expect(photoAsset.id).to(equal(assetId))
                expect(photoAsset.creationDate).to(equal(creationDate))
                expect(photoAsset.location).to(equal(location))
                expect(photoAsset.isFavorite).to(beFalse())
                expect(photoAsset.isHidden).to(beFalse())
                expect(photoAsset.fileSize).to(equal(1024 * 1024))
            }

            it("should be identifiable") {
                // This is implicitly tested by the id property, but good to be explicit
                expect(photoAsset.id).toNot(beEmpty())
            }

            it("should conform to Codable for persistence") {
                // Given
                let encoder = JSONEncoder()
                let decoder = JSONDecoder()

                // When
                let encodedData = try? encoder.encode(photoAsset)
                let decodedAsset = try? decoder.decode(PhotoAsset.self, from: encodedData!)

                // Then
                expect(encodedData).toNot(beNil())
                expect(decodedAsset).toNot(beNil())
                expect(decodedAsset?.id).to(equal(assetId))
                expect(decodedAsset?.location).to(equal(location))
            }
        }
    }
}
