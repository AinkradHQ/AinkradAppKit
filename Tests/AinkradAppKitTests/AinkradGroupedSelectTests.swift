import SwiftUI
import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite("Grouped select filtering")
struct AinkradGroupedSelectTests {
    typealias Row = AinkradGroupedRow<String>
    typealias Section = AinkradGroupedSection<String>
    let sections = [
        Section(
            header: "OpenAI",
            rows: [Row(value: "gpt-4o", title: "gpt-4o"), Row(value: "o3", title: "o3", isEnabled: false)]),
        Section(header: "Ollama", rows: [Row(value: "llama3", title: "llama3")]),
    ]

    @Test("filter keeps only sections with matching rows") func filters() {
        let out = filterGroupedSections(sections, query: "gpt")
        #expect(out.count == 1)
        #expect(out.first?.rows.map(\.value) == ["gpt-4o"])
    }
    @Test("empty query returns all sections") func all() {
        #expect(filterGroupedSections(sections, query: "").count == 2)
    }
    @Test("a header match keeps the whole section (search by group name)") func headerMatch() {
        let out = filterGroupedSections(sections, query: "ollama")
        #expect(out.count == 1)
        #expect(out.first?.header == "Ollama")
        #expect(out.first?.rows.map(\.value) == ["llama3"])  // all rows kept, not filtered by title
    }
    @Test("flattened selectable rows skip disabled + headers") func selectable() {
        #expect(selectableValues(sections) == ["gpt-4o", "llama3"])  // o3 disabled
    }
}

@Suite("Grouped select construction")
struct AinkradGroupedSelectConstructTests {
    @Test("constructs; existing selects unchanged") func constructs() {
        _ = AinkradGroupedSelect(
            sections: [
                AinkradGroupedSection(
                    header: "H",
                    rows: [AinkradGroupedRow(value: "a", title: "A", detail: "x", icon: "cloud", isEnabled: true)])
            ],
            selection: .constant("a"), triggerLabel: "Pick")
        _ = AinkradSelect(items: ["a"], selection: .constant("a"), label: { $0 })  // byte-unchanged
    }
}
