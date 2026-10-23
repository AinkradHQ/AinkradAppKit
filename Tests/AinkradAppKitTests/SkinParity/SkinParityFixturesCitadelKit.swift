import SwiftUI

@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

/// The second Citadel round (decision #60): the ten approved components, with
/// the data of the Citadel and Quest server mockups (home 02, run 05, cost 09,
/// first load 11, requirements 12, artifacts 13, project 14, accounts 15,
/// limits 16, backlog 01). The agent avatar is a separate task, so agents
/// show a stand-in ring.
@MainActor
enum SkinParityFixturesCitadelKit {
    /// A stand-in for the agent avatar: the harness ring and the initial.
    static func avatar(_ initial: String, _ color: Color = .orange, size: CGFloat = 24) -> some View {
        Text(initial)
            .font(.system(size: size * 0.45, weight: .bold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .overlay(Circle().stroke(color, lineWidth: 1.5))
    }

    struct Link: Identifiable, Equatable {
        let id: String
        let harness: String
        let model: String
        let account: String
    }

    static let chain = [
        Link(id: "a", harness: "Codex", model: "gpt-5.5", account: "account: codex-pro · effort high"),
        Link(id: "b", harness: "Claude", model: "Opus 5.5", account: "account: pool (least used, healthy)"),
        Link(id: "c", harness: "OpenCode", model: "qwen3-coder", account: "unpriced · last resort"),
    ]

    static func chainRow(_ link: Link) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                AinkradBadge(text: link.harness)
                Text(link.model)
            }
            Text(link.account).font(.caption).foregroundStyle(.secondary)
        }
    }

    /// The mockups' document preview: a heading bar and text lines.
    static var docPreview: some View {
        VStack(alignment: .leading, spacing: 5) {
            Capsule().fill(.white.opacity(0.45)).frame(width: 90, height: 6)
            Capsule().fill(.white.opacity(0.18)).frame(height: 4)
            Capsule().fill(.white.opacity(0.18)).frame(width: 110, height: 4)
            Capsule().fill(.cyan.opacity(0.3)).frame(width: 80, height: 4)
        }
        .padding(.horizontal, 12)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 10)
    }

    static var screenshotPreview: some View {
        HStack(spacing: 0) {
            Color.blue.opacity(0.35).frame(width: 50)
            Color(white: 0.1).overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 3).fill(.cyan.opacity(0.15)).frame(height: 30).padding(12)
            }
        }
    }

    static let companies = [
        AinkradWorkspace(
            id: "aink", name: "Ainkrad", kind: .own, detail: "18 agents · 3 projects", needsYou: 8),
        AinkradWorkspace(
            id: "amai", name: "AutomotiveAi", kind: .client, tint: .green, detail: "9 agents · 2 projects",
            needsYou: 2),
        AinkradWorkspace(
            id: "opt", name: "Optimus", kind: .client, tint: .purple, detail: "6 agents · 1 project"),
    ]

    static var fixtures: [SkinParityFixture] {
        [
            SkinParityFixture(
                name: "budgetBar-states",
                view: AnyView(
                    VStack(spacing: 18) {
                        AinkradBudgetBar(label: "Company · October", value: 412, limit: 900)
                        AinkradBudgetBar(label: "Issue MKT-8", value: 4.2, limit: 5)
                        AinkradBudgetBar(label: "Agent Flint", value: 40, limit: 40)
                        AinkradBudgetBar(
                            label: "claude-personal", value: 82, limit: 100, warnFraction: nil,
                            showsHardLimit: false, tone: .accentViolet)
                        AinkradBudgetBar(label: "Sprint CIT S4", value: 35, limit: 60, warnFraction: 0.7, isThick: true)
                    }.frame(width: 300))),
            SkinParityFixture(
                name: "redactedChip",
                view: AnyView(
                    HStack(spacing: 6) {
                        AinkradRedactedChip("GITHUB_TOKEN", reason: "Redacted before it was written to the log")
                        AinkradRedactedChip("run token")
                    })),
            SkinParityFixture(
                name: "skeletonRow",
                view: AnyView(
                    VStack(spacing: 12) {
                        AinkradSkeletonRow()
                        AinkradSkeletonRow(widthFraction: 0.7)
                        AinkradSkeletonRow(widthFraction: 0.85, showsAvatar: false)
                    }.frame(width: 320))),
            SkinParityFixture(
                name: "pointsPill",
                view: AnyView(
                    HStack(spacing: 10) {
                        AinkradPointsPill(points: .constant(8))
                        AinkradPointsPill(points: .constant(nil), estimator: "Toma")
                        AinkradPointsPill(points: 13)
                        AinkradPointsPill(points: nil)
                    })),
            SkinParityFixture(
                name: "workspaceSwitcher-closed",
                view: AnyView(
                    AinkradWorkspaceSwitcher(
                        workspaces: companies, selection: .constant("aink"), subtitle: "Citadel · 2 other companies"
                    ).frame(width: 260))),
            SkinParityFixture(
                name: "workspaceMenu-open",
                view: AnyView(
                    AinkradWorkspaceMenu(
                        workspaces: companies, selection: .constant("aink"), header: "Companies on citadel.ainkrad.io",
                        footnote: "Accounts, runners and cost are per company.", onNew: {})),
                sweepSize: CGSize(width: 400, height: 320)),
            SkinParityFixture(
                name: "questionCard",
                view: AnyView(
                    AinkradQuestionCard(
                        asker: "Kestrel (Dev)", issueKey: "CIT-62", context: "estimating S5", age: "4m",
                        question: "Use a **.p8 token key** (never expires) or a **.p12 certificate** per app?",
                        replies: [".p8 token key", ".p12 certificate", "Ask Toma"],
                        route: "Your answer goes to Kestrel on CIT-62 and wakes it"
                    ) {
                        avatar("K", .gray, size: 18)
                    }.frame(width: 368))),
            SkinParityFixture(
                name: "fileThumbnail-doc",
                view: AnyView(
                    HStack(spacing: 10) {
                        AinkradFileThumbnail(
                            name: "qa-report-cit-61.md", typeLabel: "report · md", agent: "Sable",
                            references: ["CIT-61"], isSelected: true
                        ) {
                            docPreview
                        } avatar: {
                            avatar("S", size: 18)
                        }
                        AinkradFileThumbnail(
                            name: "lease-expired.png", typeLabel: "png · 1440×900", agent: "Sable",
                            references: ["CIT-61"], detail: "run #428"
                        ) {
                            screenshotPreview
                        } avatar: {
                            avatar("S", size: 18)
                        }
                    }.frame(width: 368))),
            SkinParityFixture(
                name: "proposalCard-change",
                view: AnyView(
                    AinkradProposalCard(
                        author: "Toma (Lead)", title: "Lint command", tag: "citadel",
                        oldValue: "cargo clippy", newValue: "cargo clippy && cargo deny check",
                        reason: "CIT-74 shipped a yanked dependency.", onAccept: {}, onReject: {}
                    ) {
                        avatar("T")
                    }.frame(width: 368))),
            SkinParityFixture(
                name: "proposalCard-add",
                view: AnyView(
                    AinkradProposalCard(
                        author: "Sable (QA)", title: "Definition of done",
                        newValue: "API changes regenerate the Swift client", onAccept: {}, onReject: {}
                    ) {
                        avatar("S")
                    }.frame(width: 368))),
            SkinParityFixture(
                name: "reorderList-chain",
                view: AnyView(
                    AinkradReorderList(items: .constant(chain), isNumbered: true, current: "a", dimmed: ["c"]) {
                        chainRow($0)
                    }.frame(width: 340))),
            SkinParityFixture(
                name: "scopedValue",
                view: AnyView(
                    VStack(spacing: 10) {
                        AinkradScopedValue(
                            label: "Stall after", bounds: "1–120 min", value: .constant("10 min"),
                            scope: .overridden(at: "project", inheritedValue: "company 15 min"), onReset: {})
                        AinkradScopedValue(
                            label: "WIP per agent", bounds: "1–10", value: .constant("3"),
                            scope: .inherited(from: "company"))
                        AinkradScopedValue(
                            label: "Approval deadline", bounds: "1 h–7 d", value: .constant("8 h"),
                            suffix: "then to PO", scope: .inherited(from: "company"))
                    }.frame(width: 368))),
        ]
    }
}
