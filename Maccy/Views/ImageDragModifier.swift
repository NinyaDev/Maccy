import SwiftUI

struct ImageDragModifier: ViewModifier {
  let item: HistoryItemDecorator

  @ViewBuilder
  func body(content: Content) -> some View {
    if item.hasImage {
      content.onDrag {
        // Snapshot on the UI thread; provider callbacks only access independent bytes.
        let originalPNG = item.item.contents.first { $0.type == NSPasteboard.PasteboardType.png.rawValue }?.value
        guard let data = originalPNG ?? item.item.imageData else { return NSItemProvider() }
        return ImageDragPayload(data: data).itemProvider()
      } preview: {
        if let image = item.thumbnailImage ?? item.previewImage {
          Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 240, maxHeight: 160)
        }
      }
    } else {
      content
    }
  }
}
