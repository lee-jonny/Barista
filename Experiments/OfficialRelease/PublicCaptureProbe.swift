import AppKit
import ScreenCaptureKit

/// Type-check only. No function in this file is called by the experiment.
@available(macOS 26.0, *)
func menuBarImage(display: SCDisplay, regionInDisplayPoints: CGRect) async throws -> SCScreenshotOutput {
  let filter = SCContentFilter(display: display, excludingWindows: [])
  filter.includeMenuBar = true
  let configuration = SCScreenshotConfiguration()
  configuration.sourceRect = regionInDisplayPoints
  configuration.showsCursor = false
  configuration.fileURL = nil
  return try await SCScreenshotManager.captureScreenshot(
    contentFilter: filter, configuration: configuration)
}
