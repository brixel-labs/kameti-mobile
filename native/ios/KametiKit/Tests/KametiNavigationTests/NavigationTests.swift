import Foundation
import Testing
@testable import KametiNavigation

@Suite("Deep links")
struct DeepLinkTests {
    @Test func inviteLinkBecomesAJoinRoute() {
        let url = URL(string: "https://www.fhbtechservices.com/kameti/join/abc123")!
        #expect(DeepLink.route(for: url) == .join(token: "abc123"))
    }

    @Test func bareDomainAndMixedCaseHostWork() {
        #expect(DeepLink.route(for: URL(string: "https://fhbtechservices.com/kameti/join/x")!) == .join(token: "x"))
        #expect(DeepLink.route(for: URL(string: "https://WWW.FhbTechServices.com/kameti/join/x")!) == .join(token: "x"))
    }

    @Test("links we don't handle", arguments: [
        "http://www.fhbtechservices.com/kameti/join/abc",   // not https
        "https://example.com/kameti/join/abc",              // another site
        "https://www.fhbtechservices.com/kameti/join",      // no token
        "https://www.fhbtechservices.com/kameti/join/",     // empty token
        "https://www.fhbtechservices.com/kameti/other/abc", // another path
        "https://www.fhbtechservices.com/kameti/join/a/b",  // extra segment
    ])
    func ignoresOtherLinks(_ text: String) {
        #expect(DeepLink.route(for: URL(string: text)!) == nil)
    }
}

@MainActor
@Suite("AppRouter")
struct AppRouterTests {
    @Test func pushesOntoTheSelectedTabsStackOnly() {
        let router = AppRouter()
        router.push(.kametiDetail(id: "k1"))
        router.tab = .inbox
        router.push(.activity(kametiId: "k1"))
        #expect(router.homePath == [.kametiDetail(id: "k1")])
        #expect(router.inboxPath == [.activity(kametiId: "k1")])
        #expect(router.profilePath.isEmpty)
    }

    @Test func popToRootClearsOnlyTheCurrentTab() {
        let router = AppRouter()
        router.push(.kametiDetail(id: "k1"))
        router.tab = .profile
        router.push(.activity(kametiId: "k1"))
        router.popToRoot()
        #expect(router.profilePath.isEmpty)
        #expect(router.homePath == [.kametiDetail(id: "k1")])
    }

    @Test func openingAnInviteLinkShowsItOnHome() {
        let router = AppRouter()
        router.tab = .profile
        let handled = router.open(URL(string: "https://www.fhbtechservices.com/kameti/join/K7Q2MX")!)
        #expect(handled)
        #expect(router.tab == .home)
        #expect(router.homePath == [.join(token: "K7Q2MX")])
    }

    @Test func otherLinksAreLeftAlone() {
        let router = AppRouter()
        #expect(!router.open(URL(string: "https://example.com")!))
        #expect(router.homePath.isEmpty)
    }
}
