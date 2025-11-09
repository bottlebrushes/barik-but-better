import AppKit

protocol SpaceModel: Identifiable, Equatable, Codable {
    associatedtype WindowType: WindowModel
    var isFocused: Bool { get set }
    var windows: [WindowType] { get set }
}

protocol WindowModel: Identifiable, Equatable, Codable {
    var id: Int { get }
    var title: String { get }
    var appName: String? { get }
    var isFocused: Bool { get }
    var appIcon: NSImage? { get set }
}

protocol SpacesProvider {
    associatedtype SpaceType: SpaceModel
    func getSpacesWithWindows() -> [SpaceType]?
}

protocol FocusAwareSpacesProvider: SpacesProvider {
    func getFocusedSpaceId() -> String?
    func getFocusedWindowId() -> Int?
}

protocol SwitchableSpacesProvider: SpacesProvider {
    func focusSpace(spaceId: String, needWindowFocus: Bool)
    func focusWindow(windowId: String)
}

struct AnyWindow: Identifiable, Equatable {
    let id: Int
    let title: String
    let appName: String?
    let isFocused: Bool
    let appIcon: NSImage?

    init<W: WindowModel>(_ window: W) {
        self.id = window.id
        self.title = window.title
        self.appName = window.appName
        self.isFocused = window.isFocused
        self.appIcon = window.appIcon
    }

    func withFocus(_ focused: Bool) -> AnyWindow {
        AnyWindow(
            id: id,
            title: title,
            appName: appName,
            isFocused: focused,
            appIcon: appIcon)
    }

    private init(
        id: Int, title: String, appName: String?, isFocused: Bool,
        appIcon: NSImage?
    ) {
        self.id = id
        self.title = title
        self.appName = appName
        self.isFocused = isFocused
        self.appIcon = appIcon
    }

    static func == (lhs: AnyWindow, rhs: AnyWindow) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title
            && lhs.appName == rhs.appName && lhs.isFocused == rhs.isFocused
    }
}

struct AnySpace: Identifiable, Equatable {
    let id: String
    var isFocused: Bool
    let windows: [AnyWindow]

    init(id: String, isFocused: Bool, windows: [AnyWindow]) {
        self.id = id
        self.isFocused = isFocused
        self.windows = windows
    }

    init<S: SpaceModel>(_ space: S) {
        if let aero = space as? AeroSpace {
            self.init(
                id: aero.workspace, isFocused: space.isFocused,
                windows: space.windows.map { AnyWindow($0) })
        } else if let yabai = space as? YabaiSpace {
            self.init(
                id: String(yabai.id), isFocused: space.isFocused,
                windows: space.windows.map { AnyWindow($0) })
        } else {
            self.init(
                id: "0", isFocused: space.isFocused,
                windows: space.windows.map { AnyWindow($0) })
        }
    }

    func withFocus(_ isFocused: Bool) -> AnySpace {
        AnySpace(id: id, isFocused: isFocused, windows: windows)
    }

    static func == (lhs: AnySpace, rhs: AnySpace) -> Bool {
        return lhs.id == rhs.id && lhs.isFocused == rhs.isFocused
            && lhs.windows == rhs.windows
    }
}

class AnySpacesProvider {
    private let _getSpacesWithWindows: () -> [AnySpace]?
    private let _focusSpace: ((String, Bool) -> Void)?
    private let _focusWindow: ((String) -> Void)?
    private let _getFocusedSpaceId: (() -> String?)?
    private let _getFocusedWindowId: (() -> Int?)?

    init<P: SpacesProvider>(_ provider: P) {
        _getSpacesWithWindows = {
            provider.getSpacesWithWindows()?.map { AnySpace($0) }
        }
        if let switchable = provider as? any SwitchableSpacesProvider {
            _focusSpace = { spaceId, needWindowFocus in
                switchable.focusSpace(
                    spaceId: spaceId, needWindowFocus: needWindowFocus)
            }
            _focusWindow = { windowId in
                switchable.focusWindow(windowId: windowId)
            }
        } else {
            _focusSpace = nil
            _focusWindow = nil
        }
        if let focusAware = provider as? any FocusAwareSpacesProvider {
            _getFocusedSpaceId = { focusAware.getFocusedSpaceId() }
            _getFocusedWindowId = { focusAware.getFocusedWindowId() }
        } else {
            _getFocusedSpaceId = nil
            _getFocusedWindowId = nil
        }
    }

    func getSpacesWithWindows() -> [AnySpace]? {
        _getSpacesWithWindows()
    }

    func focusSpace(spaceId: String, needWindowFocus: Bool) {
        _focusSpace?(spaceId, needWindowFocus)
    }

    func focusWindow(windowId: String) {
        _focusWindow?(windowId)
    }

    func getFocusedSpaceId() -> String? {
        _getFocusedSpaceId?()
    }

    func getFocusedWindowId() -> Int? {
        _getFocusedWindowId?()
    }
}
