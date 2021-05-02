import UIKit
import MapKit

class MyTileOverlay: MKTileOverlay {

    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        let fileURL = self.fileCacheURL(forTilePath: path)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                self.processTileData(data: data, path: path, error: nil, result: result)
            }
            catch let error {
                let description = "Error: cached tile exists but not loaded. x=\(path.x), y=\(path.y), z=\(path.z), tileSize=\(self.tileSize), error=\(error.localizedDescription)"
                result(nil, NSError(domain: "MyTileOverlay", code: 1, userInfo: [NSLocalizedDescriptionKey : description]))
            }
            return
        }
        
        super.loadTile(at: path) { (data: Data?, error: Error?) in
            self.saveTileToCache(data: data, tilePath: path)
            self.processTileData(data: data, path: path, error: error, result: result)
        }
    }
    
    private func fileCacheURL(forTilePath path:MKTileOverlayPath) -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("c.tile.openstreetmap.org/\(path.z)/\(path.x)/\(path.y).png")
    }
    
    private func saveTileToCache(data: Data?, tilePath: MKTileOverlayPath) {
        let fileURL = self.fileCacheURL(forTilePath: tilePath)
        
        let folderURL = fileURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            do {
                try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            }
            catch let error {
                print("Error when creating cache folder: desc=\(error.localizedDescription); url=\(folderURL.path)")
                return
            }
        }
        
        do { try data?.write(to: fileURL) }
        catch let error {
            print("Error when writing tile cache: desc=\(error.localizedDescription); url=\(fileURL.path)")
        }
    }
    
    private func processTileData(data: Data?, path: MKTileOverlayPath, error: Error?, result: @escaping (Data?, Error?) -> Void) {
        guard let data = data else {
            let description = "Error: data is nil: x=\(path.x), y=\(path.y), z=\(path.z)"
            result(nil, NSError(domain: "MyTileOverlay", code: 1, userInfo: [NSLocalizedDescriptionKey : description]))
            return
        }
        scaleLoadedTile(data: data, path: path, result: result)
    }
    
    private func scaleLoadedTile(data: Data, path: MKTileOverlayPath, result: (Data?, Error?) -> Void) {
        guard let image = UIImage(data: data) else {
            let description = "Error: Failed to parse tile image: x=\(path.x), y=\(path.y), z=\(path.z)"
            result(nil, NSError(domain: "MyTileOverlay", code: 1, userInfo: [NSLocalizedDescriptionKey : description]))
            return
        }
        
        UIGraphicsBeginImageContext(self.tileSize)
        image.draw(in: CGRect(x: 0,
                              y: 0,
                              width: self.tileSize.width,
                              height: self.tileSize.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let newImage = newImage
        {
            let newData = newImage.pngData()
            result(newData, nil)
        }
        else
        {
            let description = "Error: Failed to draw tile: x=\(path.x), y=\(path.y), z=\(path.z), tileSize=\(self.tileSize)"
            result(nil, NSError(domain: "MyTileOverlay", code: 1, userInfo: [NSLocalizedDescriptionKey : description]))
        }
    }
}
