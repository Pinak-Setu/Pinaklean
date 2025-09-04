
import Foundation

/// Represents a photo asset from the user's photo library.
public struct PhotoAsset: Identifiable, Codable, Hashable {
    /// A unique, persistent identifier for the asset.
    public let id: String
    
    /// The date the asset was originally created.
    public let creationDate: Date
    
    /// The local file path or URI for the asset's data.
    public let location: String
    
    /// A flag indicating if the user has marked this asset as a favorite.
    public let isFavorite: Bool
    
    /// A flag indicating if the asset is hidden from the user's main library view.
    public let isHidden: Bool
    
    /// The size of the asset's file in bytes.
    public let fileSize: Int64
    
    public init(id: String, creationDate: Date, location: String, isFavorite: Bool, isHidden: Bool, fileSize: Int64) {
        self.id = id
        self.creationDate = creationDate
        self.location = location
        self.isFavorite = isFavorite
        self.isHidden = isHidden
        self.fileSize = fileSize
    }
}
