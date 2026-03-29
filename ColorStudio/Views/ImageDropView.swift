import SwiftUI
import UniformTypeIdentifiers

struct ImageDropView: View {
    @Binding var extractedColors: [ColorModel]
    @State private var isTargeted = false
    @State private var isExtracting = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 2, dash: [8])
                    )
                    .foregroundColor(isTargeted ? .accentColor : .gray.opacity(0.5))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
                    )

                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundColor(isTargeted ? .accentColor : .gray)

                    Text(isTargeted ? "Drop image here" : "Drag & drop image to extract colors")
                        .font(.headline)
                        .foregroundColor(isTargeted ? .accentColor : .secondary)

                    if isExtracting {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
                .padding(40)
            }
            .frame(height: 200)
            .onDrop(of: [.image, .fileURL], isTargeted: $isTargeted) { providers in
                handleDrop(providers: providers)
                return true
            }

            if !extractedColors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Extracted Colors")
                        .font(.headline)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(extractedColors) { color in
                                VStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(color.color)
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )

                                    Text(color.hexString)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }

    private func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }

        isExtracting = true

        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, error in
                DispatchQueue.main.async {
                    if let data = item as? Data, let image = NSImage(data: data) {
                        extractColors(from: image)
                    } else if let url = item as? URL, let image = NSImage(contentsOf: url) {
                        extractColors(from: image)
                    }
                    isExtracting = false
                }
            }
        } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                DispatchQueue.main.async {
                    if let url = item as? URL, let image = NSImage(contentsOf: url) {
                        extractColors(from: image)
                    }
                    isExtracting = false
                }
            }
        }
    }

    private func extractColors(from image: NSImage) {
        DispatchQueue.global(qos: .userInitiated).async {
            let colors = ImageColorExtractor.extractDominantColors(from: image, count: 8)
            DispatchQueue.main.async {
                self.extractedColors = colors
            }
        }
    }
}
