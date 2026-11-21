import AppKit
import CoreGraphics
import ScreenCaptureKit

@MainActor
final class LabDelegate: NSObject, NSApplicationDelegate {
  private var window: NSWindow!
  private var output: NSTextView!
  private var items: [NSStatusItem] = []
  private var spacers: [NSStatusItem] = []
  private var samples: [NSStatusItem] = []
  private var resetTask: Task<Void, Never>?

  func applicationDidFinishLaunching(_ notification: Notification) {
    if CommandLine.arguments.contains("--capture-probe") {
      guard CGPreflightScreenCaptureAccess() else {
        print("SKIPPED: screen capture preflight is false; no permission request issued")
        NSApp.terminate(nil)
        return
      }
      Task { @MainActor in
        do {
          // One pixel, memory only. Tests capture transport, not icon recognition.
          let image = try await SCScreenshotManager.captureImage(
            in: CGRect(x: 0, y: 0, width: 1, height: 1))
          print("captureTransport=success pixels=\(image.width)x\(image.height)")
        } catch {
          FileHandle.standardError.write(Data("captureTransport=failed \(error)\n".utf8))
          exit(EXIT_FAILURE)
        }
        NSApp.terminate(nil)
      }
      return
    }
    if CommandLine.arguments.contains("--diagnose") {
      print("sandboxContainer=\(ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] ?? "absent")")
      print("screenCapturePreflight=\(CGPreflightScreenCaptureAccess())")
      print("listenEventPreflight=\(CGPreflightListenEventAccess())")
      print("postEventPreflight=\(CGPreflightPostEventAccess())")
      for screen in NSScreen.screens {
        print("display width=\(screen.frame.width) trailing=\(String(describing: screen.auxiliaryTopRightArea?.width))")
      }
      NSApp.terminate(nil)
      return
    }
    window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 690, height: 430),
      styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
    window.title = "Barista Lab — public geometry experiment"
    let root = NSView(frame: NSRect(x: 0, y: 0, width: 690, height: 430))
    let run = NSButton(title: "Run 5-second OWN-item trial", target: self, action: #selector(runTrial))
    run.frame = NSRect(x: 18, y: 390, width: 310, height: 28)
    let restore = NSButton(title: "Remove trial items", target: self, action: #selector(reset))
    restore.frame = NSRect(x: 360, y: 390, width: 200, height: 28)
    output = NSTextView(frame: NSRect(x: 18, y: 18, width: 650, height: 360))
    output.isEditable = false
    output.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
    output.string = "No screen capture or input injection.\nTrial changes only this app's status-item lengths.\nClose other menu managers first; trial refuses known conflicts.\nFrame logs alone do not prove other apps' icons are usable in «.\nObserve the menu bar while running; items reset after 5 seconds.\n"
    root.addSubview(run); root.addSubview(restore); root.addSubview(output)
    window.contentView = root
    window.center(); window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  @objc private func runTrial() {
    reset()
    let conflicts = NSWorkspace.shared.runningApplications.filter {
      let id = ($0.bundleIdentifier ?? "").lowercased()
      return id == "dev.eden.barista" || ["bartender", "barbee", "hiddenbar", "minimalbar", "minibar", "thaw", "menubarhide", "jordanbaird.ice"].contains(where: id.contains)
    }
    guard conflicts.isEmpty else {
      append("REFUSED: another menu manager is running: \(conflicts.compactMap(\.localizedName).joined(separator: ", ")).")
      return
    }
    let displays = NSScreen.screens.map {
      OverflowDisplay(width: Double($0.frame.width),
        trailingWidth: $0.auxiliaryTopRightArea.map { Double($0.width) })
    }
    guard let plan = OverflowPlan.propose(displays: displays) else {
      append("UNSUPPORTED: no conservative proposal covers this display arrangement.")
      return
    }
    let control = NSStatusBar.system.statusItem(withLength: 36)
    control.button?.title = "LAB"
    control.button?.target = self; control.button?.action = #selector(reset)
    items.append(control)
    for _ in 0..<plan.itemCount {
      let spacer = NSStatusBar.system.statusItem(withLength: 0)
      spacer.isVisible = false
      spacers.append(spacer); items.append(spacer)
    }
    for label in ["T1", "T2"] {
      let sample = NSStatusBar.system.statusItem(withLength: 28)
      sample.button?.title = label
      sample.button?.setAccessibilityLabel("Barista Lab specimen \(label)")
      samples.append(sample); items.append(sample)
    }
    append("Trial proposal: \(plan.itemCount) own spacers × \(plan.itemWidth) pt")
    resetTask = Task { @MainActor [weak self] in
      do {
        try await Task.sleep(for: .seconds(1))
        guard let self else { return }
        self.describe("expanded")
        for spacer in self.spacers { spacer.length = plan.itemWidth; spacer.isVisible = true }
        try await Task.sleep(for: .seconds(1))
        self.describe("inflated")
        try await Task.sleep(for: .seconds(4))
        self.reset()
        self.append("Trial restored. OTHER-app selection, reboot, secondary displays and App Review are unverified.")
      } catch { return }
    }
  }

  private func describe(_ phase: String) {
    for (index, item) in items.enumerated() {
      append("\(phase) item=\(index) length=\(item.length) visible=\(item.isVisible) window=\(String(describing: item.button?.window?.frame))")
    }
  }
  private func append(_ text: String) { output.string += text + "\n" }
  @objc private func reset() {
    resetTask?.cancel(); resetTask = nil
    for item in items { NSStatusBar.system.removeStatusItem(item) }
    items.removeAll(); spacers.removeAll(); samples.removeAll()
  }
  func applicationWillTerminate(_ notification: Notification) { reset() }
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

let app = NSApplication.shared
let delegate = LabDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
