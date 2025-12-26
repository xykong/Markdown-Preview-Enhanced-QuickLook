import Cocoa
import QuickLookUI
import os.log

public class PreviewViewController: NSViewController, QLPreviewingController {

    var statusLabel: NSTextField!
    
    // Create a custom log object for easy filtering in Console.app
    // Subsystem: com.markdownquicklook.app
    // Category: MarkdownPreview
    private let logger = OSLog(subsystem: "com.markdownquicklook.app", category: "MarkdownPreview")
    
    public override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        os_log("🔵 init(nibName:bundle:) called", log: logger, type: .debug)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        os_log("🔵 init(coder:) called", log: logger, type: .debug)
    }
    
    public override func loadView() {
        os_log("🔵 loadView called", log: logger, type: .debug)
        // Create the main view programmatically with a default size
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 200))
        self.view.autoresizingMask = [.width, .height]
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        os_log("🔵 viewDidLoad called", log: logger, type: .default)
        
        // Simple light background
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.white.cgColor
        
        // Create a simple label
        statusLabel = NSTextField(labelWithString: "Hello Markdown Preview")
        statusLabel.font = NSFont.systemFont(ofSize: 24, weight: .bold)
        statusLabel.textColor = NSColor.black
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(statusLabel)
        
        // Center the label
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
    }

    public func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        
        os_log("🔵 preparePreviewOfFile called for: %{public}@", log: logger, type: .default, url.path)
        
        // Update label to show we received the file
        DispatchQueue.main.async {
            self.statusLabel.stringValue = "Markdown Preview\nFile: \(url.lastPathComponent)"
        }
        
        handler(nil)
    }
}
