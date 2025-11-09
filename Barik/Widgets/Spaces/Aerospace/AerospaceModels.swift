import AppKit

struct AeroWindow: WindowModel {
    let id: Int
    let title: String
    let appName: String?
    var isFocused: Bool = false
    var appIcon: NSImage?
    let workspace: String?
    let reportedFocus: Bool?

    enum CodingKeys: String, CodingKey {
        case id = "window-id"
        case title = "window-title"
        case appName = "app-name"
        case workspace
        case hasFocus = "has-focus"
        case isFocusedFlag = "is-focused"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        appName = try container.decodeIfPresent(String.self, forKey: .appName)
        workspace = try container.decodeIfPresent(
            String.self, forKey: .workspace)
        let focusByHasFocus = try container.decodeIfPresent(
            Bool.self, forKey: .hasFocus)
        let focusByIsFocused = try container.decodeIfPresent(
            Bool.self, forKey: .isFocusedFlag)
        reportedFocus = focusByHasFocus ?? focusByIsFocused
        isFocused = reportedFocus ?? false
        if let name = appName {
            appIcon = IconCache.shared.icon(for: name)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(appName, forKey: .appName)
        try container.encodeIfPresent(workspace, forKey: .workspace)
        try container.encode(isFocused, forKey: .isFocusedFlag)
    }
}

struct AeroSpace: SpaceModel {
    typealias WindowType = AeroWindow
    let workspace: String
    var id: String { workspace }
    var isFocused: Bool = false
    var windows: [AeroWindow] = []
    let reportedFocus: Bool?

    enum CodingKeys: String, CodingKey {
        case workspace
        case hasFocus = "has-focus"
        case isFocusedFlag = "is-focused"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        workspace = try container.decode(String.self, forKey: .workspace)
        let focusByHasFocus = try container.decodeIfPresent(
            Bool.self, forKey: .hasFocus)
        let focusByIsFocused = try container.decodeIfPresent(
            Bool.self, forKey: .isFocusedFlag)
        reportedFocus = focusByHasFocus ?? focusByIsFocused
        isFocused = reportedFocus ?? false
    }

    init(
        workspace: String, isFocused: Bool = false,
        windows: [AeroWindow] = [], reportedFocus: Bool? = nil
    ) {
        self.workspace = workspace
        self.isFocused = isFocused
        self.windows = windows
        self.reportedFocus = reportedFocus
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(workspace, forKey: .workspace)
        try container.encode(isFocused, forKey: .isFocusedFlag)
    }
}
