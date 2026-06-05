import Testing
@testable import Headroom

@Test
func headroomTierComparable() {
    #expect(HeadroomTier.high > .medium)
    #expect(HeadroomTier.low < .ultra)
}

@Test
func headroomTierDowngradeClampsAtLow() {
    #expect(HeadroomTier.low.downgraded() == .low)
    #expect(HeadroomTier.ultra.downgraded() == .high)
    #expect(HeadroomTier.ultra.downgraded(by: 3) == .low)
}

@Test
func headroomTierUpgradeClampsAtUltra() {
    #expect(HeadroomTier.ultra.upgraded() == .ultra)
    #expect(HeadroomTier.low.upgraded() == .medium)
    #expect(HeadroomTier.low.upgraded(by: 3) == .ultra)
}
