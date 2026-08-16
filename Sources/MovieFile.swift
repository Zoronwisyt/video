import Foundation
import CoreTransferable
import UniformTypeIdentifiers

struct MovieFile: Transferable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .movie) { received in
            MovieFile(url: received.file)
        }
    }
}
