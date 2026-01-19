import SwiftUI

// 剪贴板历史列表视图
struct ClipboardHistoryView: View {
    @ObservedObject var monitor = ClipboardMonitor.shared
    @State private var searchText = ""
    @State private var hoveredItemId: UUID?
    
    var filteredItems: [ClipboardItem] {
        monitor.search(searchText)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("搜索历史记录...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // 历史列表
            if filteredItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "暂无剪贴板历史" : "未找到匹配内容")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(filteredItems) { item in
                            ClipboardItemRow(
                                item: item,
                                isHovered: hoveredItemId == item.id,
                                onCopy: { monitor.copyToClipboard(item) },
                                onDelete: { monitor.deleteItem(item) }
                            )
                            .onHover { isHovered in
                                hoveredItemId = isHovered ? item.id : nil
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Divider()
            
            // 底部工具栏
            HStack {
                Text("\(filteredItems.count) 条记录")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: { monitor.clearHistory() }) {
                    Text("清空")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
                .disabled(filteredItems.isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 320, height: 400)
    }
}

// 单个剪贴板项目行
struct ClipboardItemRow: View {
    let item: ClipboardItem
    let isHovered: Bool
    let onCopy: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            // 内容预览
            contentPreview
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 时间
            Text(item.formattedTime)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            // 操作按钮
            if isHovered {
                HStack(spacing: 4) {
                    Button(action: onCopy) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .help("复制")
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .help("删除")
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isHovered ? Color(NSColor.selectedContentBackgroundColor).opacity(0.5) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            // 使用 Helper 统一处理粘贴
            PasteboardHelper.shared.paste(item: item)
        }
    }
    
    @ViewBuilder
    var contentPreview: some View {
        switch item.contentType {
        case .text:
            Text(item.previewText)
                .font(.system(size: 12))
                .lineLimit(2)
                .truncationMode(.tail)
        case .image:
            HStack(spacing: 8) {
                if let image = item.nsImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .cornerRadius(4)
                }
                Text("图片")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        case .file:
            HStack(spacing: 6) {
                Image(systemName: "folder.fill")
                    .foregroundColor(.blue)
                Text(item.previewText)
                    .font(.system(size: 12))
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    ClipboardHistoryView()
}
