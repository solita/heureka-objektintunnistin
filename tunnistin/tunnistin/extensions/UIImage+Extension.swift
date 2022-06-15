import Foundation
import UIKit

extension UIImage {

  /// Function will load an image resource from file/asset, looking first at documents folder (for customization), then in-app resources.
  /// Supports pdf/png/jpg images in documents folder.
  /// - Parameter resourceName: name of the image resource to load without type extension.
  /// - Returns: `UIImage` or nil, if resource is not found
  class func imageFromResource(named resourceName: String) -> UIImage? {
    if let documentDir: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last {
      print(documentDir)
      let pdfUrl = documentDir.appendingPathComponent("\(resourceName).pdf")
      if let image = UIImage.drawPDFfromURL(url: pdfUrl) {
        return image
      }
      let pngUrl = documentDir.appendingPathComponent("\(resourceName).png")
      if let imageData = try? Data(contentsOf: pngUrl), let image = UIImage.init(data: imageData) {
        return image
      }
      let jpgUrl = documentDir.appendingPathComponent("\(resourceName).jpg")
      if let imageData = try? Data(contentsOf: jpgUrl), let image = UIImage.init(data: imageData) {
        return image
      }
    }
    // no overrides found, try from bundle
    return UIImage.init(named: resourceName)
  }

  /// Function will load a gif animation from file/asset, looking first at documents folder, then in-app resources.
  /// - Parameter resourceName: name of the gif resource to load without type extension
  /// - Returns: Array of `UIImage` objects representing the frames in the animation or nil, if resource is not found
  class func gifFramesFrom(named resourceName: String) -> [UIImage]? {
    if let documentDir: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last {
      print(documentDir.absoluteString)
      var source: CGImageSource?
      let gifUrl = documentDir.appendingPathComponent("\(resourceName).gif")
      if let gifData = try? Data(contentsOf: gifUrl),
         let gif = CGImageSourceCreateWithData(gifData as CFData, nil) {
        source = gif
      } else if let bundleGifUrl = Bundle.main.url(forResource: resourceName, withExtension: "gif"),
                let gifData = try? Data(contentsOf: bundleGifUrl),
                let gif = CGImageSourceCreateWithData(gifData as CFData, nil) {
        source = gif
      }

      if let source = source {
        var images = [UIImage]()
        let imageCount = CGImageSourceGetCount(source)
        for i in 0 ..< imageCount {
          if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
            images.append(UIImage(cgImage: image))
          }
        }
        return images
      }
    }
    return nil
  }

  private class func drawPDFfromURL(url: URL) -> UIImage? {
    guard let document = CGPDFDocument(url as CFURL) else { return nil }
    guard let page = document.page(at: 1) else { return nil }

    let pageRect = page.getBoxRect(.mediaBox)
    let renderer = UIGraphicsImageRenderer(size: pageRect.size)
    let img = renderer.image { ctx in
      UIColor.clear.set()
      ctx.fill(pageRect)

      ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
      ctx.cgContext.scaleBy(x: 1.0, y: -1.0)

      ctx.cgContext.drawPDFPage(page)
    }

    return img
  }

}
