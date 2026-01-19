import SwiftUI

// 菜单栏视图
struct MenuBarView: View {
    @ObservedObject var monitor = ClipboardMonitor.shared
    @State private var searchText = ""
    
    var filteredItems: [ClipboardItem] {
        monitor.search(searchText)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("📋 剪贴板历史")
                    .font(.headline)
                Spacer()
                Button(action: { NSApp.terminate(nil) }) {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.caption)
                TextField("搜索...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
            }
            .padding(8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            
            Divider()
            
            // 列表
            if filteredItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("暂无记录")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(filteredItems.prefix(20)) { item in
                            MenuBarItemRow(item: item) {
                                // 使用 Helper 统一处理粘贴
                                PasteboardHelper.shared.paste(item: item)
                            }
                        }
                    }
                    .padding(4)
                }
            }
            
            Divider()
            
            // 底部
            HStack {
                Text("⌘⇧V 快速调出")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Button("清空") {
                    monitor.clearHistory()
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundColor(.red)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .frame(width: 300, height: 380)
    }
}

// 菜单栏项目行
struct MenuBarItemRow: View {
    let item: ClipboardItem
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 8) {
            // 类型图标
            typeIcon
                .frame(width: 20)
            
            // 内容
            Text(item.previewText)
                .font(.system(size: 11))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 时间
            Text(item.formattedTime)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isHovered ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(4)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onTap()
        }
    }
    
    @ViewBuilder
    var typeIcon: some View {
        switch item.contentType {
        case .text:
            Image(systemName: "doc.text")
                .foregroundColor(.blue)
                .font(.caption)
        case .image:
            if let image = item.nsImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 20, height: 20)
                    .cornerRadius(2)
            } else {
                Image(systemName: "photo")
                    .foregroundColor(.green)
                    .font(.caption)
            }
        case .file:
            Image(systemName: "folder.fill")
                .foregroundColor(.orange)
                .font(.caption)
        }
    }
}

#Preview {
    MenuBarView()
}
