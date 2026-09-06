import Testing
@testable import AinkradAppKitContract

@Suite("AinkradMotionBudget")
struct AinkradMotionBudgetTests {
    @Test func fullMotionCapsAtThirtyFPS() {
        let budget = AinkradMotionBudget(isAppActive: true, isWindowVisible: true,
                                         isLowPower: false, reduceMotion: false)
        #expect(budget.minimumInterval == 1.0 / 30.0)
        #expect(budget.isAnimating)
    }

    @Test func anInvisibleWindowFreezesEntirely() {
        let budget = AinkradMotionBudget(isAppActive: true, isWindowVisible: false,
                                         isLowPower: false, reduceMotion: false)
        #expect(budget.minimumInterval == nil)
        #expect(!budget.isAnimating)
    }

    @Test func invisibilityBeatsEveryOtherInput() {
        // Even the most permissive other flags cannot un-freeze a hidden window.
        let budget = AinkradMotionBudget(isAppActive: true, isWindowVisible: false,
                                         isLowPower: false, reduceMotion: false)
        #expect(budget.minimumInterval == nil)
    }

    @Test func aBackgroundedButVisibleWindowDropsToFiveFPS() {
        let budget = AinkradMotionBudget(isAppActive: false, isWindowVisible: true,
                                         isLowPower: false, reduceMotion: false)
        #expect(budget.minimumInterval == 1.0 / 5.0)
    }

    @Test func lowPowerModeDropsToTenFPS() {
        let budget = AinkradMotionBudget(isAppActive: true, isWindowVisible: true,
                                         isLowPower: true, reduceMotion: false)
        #expect(budget.minimumInterval == 1.0 / 10.0)
    }

    @Test func reduceMotionDropsToTenFPS() {
        let budget = AinkradMotionBudget(isAppActive: true, isWindowVisible: true,
                                         isLowPower: false, reduceMotion: true)
        #expect(budget.minimumInterval == 1.0 / 10.0)
    }

    @Test func backgroundedBeatsLowPowerBecauseItIsTheCheaper() {
        let budget = AinkradMotionBudget(isAppActive: false, isWindowVisible: true,
                                         isLowPower: true, reduceMotion: true)
        #expect(budget.minimumInterval == 1.0 / 5.0)
    }

    @Test func fullIsTheUnhostedDefaultSoPreviewsStillAnimate() {
        #expect(AinkradMotionBudget.full.isAnimating)
        #expect(AinkradMotionBudget.full.minimumInterval == 1.0 / 30.0)
    }

    @Test func frozenDoesNotAnimate() {
        #expect(!AinkradMotionBudget.frozen.isAnimating)
    }
}
