import XCTest
import RenderPay

class StripeServiceTests: XCTestCase {
    var service: StripeService!
    
    override func setUp() {
        super.setUp()
        
        service = StripeService()
        StripeService.clientId = "123"
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    func testOAuthUrl() {
        // This is an example of a functional test case.
        let userId = "abc"
        let url = service.getOAuthUrl(userId)
        XCTAssertEqual(url, "https://connect.stripe.com/oauth/authorize?response_type=code&client_id=123&scope=read_write&state=abc", "OAuth url should be generated from clientId and userId")
    }
}
