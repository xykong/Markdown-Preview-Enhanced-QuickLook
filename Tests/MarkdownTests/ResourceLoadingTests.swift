import XCTest

class ResourceLoadingTests: XCTestCase {
    
    func testIndexHtmlExists() {
        let testBundle = Bundle(for: ResourceLoadingTests.self)
        let foundURL = ResourceLoader.findIndexHtml(in: testBundle)
        print("Found URL: \(String(describing: foundURL))")
    }
}
