import Foundation
import Testing

@Test
func privacyManifestDeclaresDiskSpaceReasonAndNoTracking() throws {
    let manifestURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Sources/Headroom/PrivacyInfo.xcprivacy")

    let data = try Data(contentsOf: manifestURL)
    let propertyList = try #require(
        PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
    )

    #expect(propertyList["NSPrivacyTracking"] as? Bool == false)
    #expect((propertyList["NSPrivacyTrackingDomains"] as? [Any])?.isEmpty == true)
    #expect((propertyList["NSPrivacyCollectedDataTypes"] as? [Any])?.isEmpty == true)

    let accessedAPITypes = try #require(propertyList["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
    let diskSpaceEntry = try #require(
        accessedAPITypes.first {
            $0["NSPrivacyAccessedAPIType"] as? String == "NSPrivacyAccessedAPICategoryDiskSpace"
        }
    )

    #expect(diskSpaceEntry["NSPrivacyAccessedAPITypeReasons"] as? [String] == ["E174.1"])
}
