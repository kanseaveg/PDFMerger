import SwiftUI
import PDFKit
import UniformTypeIdentifiers
import AppKit

// MARK: - Data Model

struct PDFFileItem: Identifiable, Equatable, Hashable {
    let id = UUID()
    let url: URL
    let fileType: FileType
    var name: String { url.lastPathComponent }

    enum FileType: String {
        case pdf, png, jpeg
        var icon: String {
            switch self {
            case .pdf: return "doc.richtext"
            case .png, .jpeg: return "photo"
            }
        }
        var iconColor: Color {
            switch self {
            case .pdf: return .red
            case .png, .jpeg: return .blue
            }
        }
    }

    var pageCount: Int {
        if fileType == .pdf {
            return PDFDocument(url: url)?.pageCount ?? 0
        }
        return 1 // 图片算1页
    }

    static var supportedExtensions: Set<String> {
        ["pdf", "png", "jpg", "jpeg"]
    }

    static func fileType(for url: URL) -> FileType? {
        switch url.pathExtension.lowercased() {
        case "pdf": return .pdf
        case "png": return .png
        case "jpg", "jpeg": return .jpeg
        default: return nil
        }
    }
}

// MARK: - Image to PDF Helper

func imageToPDFPage(_ url: URL) -> PDFPage? {
    guard let image = NSImage(contentsOf: url),
          let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        return nil
    }
    let width = CGFloat(cgImage.width)
    let height = CGFloat(cgImage.height)
    let pdfData = NSMutableData()
    var mediaBox = CGRect(x: 0, y: 0, width: width, height: height)
    guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
          let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
        return nil
    }
    context.beginPDFPage(nil)
    context.draw(cgImage, in: mediaBox)
    context.endPDFPage()
    context.closePDF()
    guard let provider = CGDataProvider(data: pdfData as CFData),
          let pdfDoc = CGPDFDocument(provider),
          let _ = pdfDoc.page(at: 1) else {
        return nil
    }
    let doc = PDFDocument(data: pdfData as Data)
    return doc?.page(at: 0)
}

// MARK: - App Entry

@main
struct PDFMergerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 500, minHeight: 400)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 600, height: 500)
    }
}

// MARK: - Main View

struct ContentView: View {
    @State private var files: [PDFFileItem] = []
    @State private var draggingItem: PDFFileItem?
    @State private var isTargeted = false
    @State private var mergeMessage: String?
    @State private var isMerging = false

    var totalPages: Int {
        files.reduce(0) { $0 + $1.pageCount }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("PDF 合并工具")
                    .font(.title2.bold())
                Spacer()
                Text("\(files.count) 个文件，共 \(totalPages) 页")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
            .padding()

            Divider()

            // File list or drop zone
            if files.isEmpty {
                dropZonePlaceholder
            } else {
                fileListView
            }

            Divider()

            // Bottom bar
            HStack {
                Button {
                    addFilesViaPanel()
                } label: {
                    Label("添加文件", systemImage: "plus")
                }

                Button {
                    files.removeAll()
                    mergeMessage = nil
                } label: {
                    Label("清空", systemImage: "trash")
                }
                .disabled(files.isEmpty)

                Spacer()

                if let msg = mergeMessage {
                    Text(msg)
                        .font(.callout)
                        .foregroundStyle(msg.contains("✓") ? .green : .red)
                        .transition(.opacity)
                }

                Button {
                    mergeFiles()
                } label: {
                    Label("合并 PDF", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)
                .disabled(files.count < 2 || isMerging)
            }
            .padding()
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isTargeted ? Color.accentColor : Color.clear, lineWidth: 3)
        )
        .animation(.default, value: isTargeted)
        .animation(.default, value: mergeMessage)
    }

    // MARK: - Drop Zone Placeholder

    var dropZonePlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("将 PDF / PNG / JPEG 文件拖到这里")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("图片会自动转为 PDF 页面，一起合并")
                .font(.callout)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isTargeted ? Color.accentColor.opacity(0.05) : Color.clear)
    }

    // MARK: - File List

    var fileListView: some View {
        List {
            ForEach(files) { file in
                HStack {
                    Image(systemName: file.fileType.icon)
                        .foregroundStyle(file.fileType.iconColor)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(file.name)
                            .lineLimit(1)
                        HStack(spacing: 4) {
                            Text(file.fileType.rawValue.uppercased())
                                .font(.caption2.bold())
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(file.fileType.iconColor.opacity(0.15))
                                .cornerRadius(3)
                            Text("\(file.pageCount) 页")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button {
                        files.removeAll { $0.id == file.id }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 2)
            }
            .onMove { from, to in
                files.move(fromOffsets: from, toOffset: to)
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }

    // MARK: - Actions

    func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url") { data, _ in
                var url: URL?
                if let data = data as? Data {
                    url = URL(dataRepresentation: data, relativeTo: nil)
                } else if let urlData = data as? URL {
                    url = urlData
                }
                guard let resolvedURL = url else { return }
                guard let fileType = PDFFileItem.fileType(for: resolvedURL) else { return }
                DispatchQueue.main.async {
                    if !self.files.contains(where: { $0.url == resolvedURL }) {
                        self.files.append(PDFFileItem(url: resolvedURL, fileType: fileType))
                    }
                }
            }
        }
        return true
    }

    func addFilesViaPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [UTType.pdf, UTType.png, UTType.jpeg]
        panel.message = "选择要合并的 PDF / PNG / JPEG 文件"

        if panel.runModal() == .OK {
            for url in panel.urls {
                if !files.contains(where: { $0.url == url }),
                   let fileType = PDFFileItem.fileType(for: url) {
                    files.append(PDFFileItem(url: url, fileType: fileType))
                }
            }
        }
    }

    func mergeFiles() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.pdf]
        savePanel.nameFieldStringValue = "merged.pdf"
        savePanel.message = "选择合并后 PDF 的保存位置"

        guard savePanel.runModal() == .OK, let saveURL = savePanel.url else { return }

        isMerging = true
        mergeMessage = nil

        DispatchQueue.global(qos: .userInitiated).async {
            let mergedPDF = PDFDocument()
            var pageIndex = 0

            for file in files {
                if file.fileType == .pdf {
                    guard let doc = PDFDocument(url: file.url) else { continue }
                    for i in 0..<doc.pageCount {
                        if let page = doc.page(at: i) {
                            mergedPDF.insert(page, at: pageIndex)
                            pageIndex += 1
                        }
                    }
                } else {
                    // PNG / JPEG → PDF page
                    if let page = imageToPDFPage(file.url) {
                        mergedPDF.insert(page, at: pageIndex)
                        pageIndex += 1
                    }
                }
            }

            let success = mergedPDF.write(to: saveURL)

            DispatchQueue.main.async {
                isMerging = false
                mergeMessage = success
                    ? "✓ 合并成功！共 \(pageIndex) 页"
                    : "✗ 合并失败，请重试"
            }
        }
    }
}
