import Foundation
import AppKit

// 剪贴板内容类型
enum ClipboardContentType: Codable {
    case text
    case image
    case file
}

// 剪贴板项目模型
struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let contentType: ClipboardContentType
    let timestamp: Date
    
    // 文本内容
    var textContent: String?
    
    // 图片数据 (Base64编码存储)
    var imageData: Data?
    
    // 文件路径
    var filePaths: [String]?
    
    init(text: String) {
        self.id = UUID()
        self.contentType = .text
        self.timestamp = Date()
        self.textContent = text
    }
    
    init(imageData: Data) {
        self.id = UUID()
        self.contentType = .image
        self.timestamp = Date()
        self.imageData = imageData
    }
    
    init(filePaths: [String]) {
        self.id = UUID()
        self.contentType = .file
        self.timestamp = Date()
        self.filePaths = filePaths
    }
    
    // 获取预览文本
    var previewText: String {
        switch contentType {
        case .text:
            let text = textContent ?? ""
            return text.count > 100 ? String(text.prefix(100)) + "..." : text
        case .image:
            return "📷 图片"
        case .file:
            if let paths = filePaths, !paths.isEmpty {
                let fileName = (paths.first! as NSString).lastPathComponent
                return "📁 \(fileName)" + (paths.count > 1 ? " 等\(paths.count)个文件" : "")
            }
            return "📁 文件"
        }
    }
    
    // 获取NSImage (用于图片类型)
    var nsImage: NSImage? {
        guard let data = imageData else { return nil }
        return NSImage(data: data)
    }
    
    // 格式化时间
    var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        switch (lhs.contentType, rhs.contentType) {
        case (.text, .text):
            return lhs.textContent == rhs.textContent
        case (.image, .image):
            return lhs.imageData == rhs.imageData
        case (.file, .file):
            return lhs.filePaths == rhs.filePaths
        default:
            return false
        }
    }
}
