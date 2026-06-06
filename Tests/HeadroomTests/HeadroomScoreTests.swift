import Testing
@testable import Headroom

@Test
func headroomScoreClampsToRange() {
    #expect(HeadroomScore(-10).rawValue == 0)
    #expect(HeadroomScore(120).rawValue == 100)
}

@Test
func headroomScoreMapsToTier() {
    #expect(HeadroomScore(39).tier == .low)
    #expect(HeadroomScore(40).tier == .medium)
    #expect(HeadroomScore(70).tier == .high)
    #expect(HeadroomScore(82).tier == .ultra)
}

@Test
func headroomScorePenaltyClamps() {
    #expect(HeadroomScore(20).penalized(by: 40).rawValue == 0)
    #expect(HeadroomScore(84).penalized(by: 8).rawValue == 76)
}
