// design-lint: allow-file radius-literal,opacity-literal,frame-literal,chamfer-literal,motion-literal theme layer — component token aggregate struct
import Foundation

package struct AinkradComponentGroup1: Equatable, Sendable {
    var panel: PanelTokens
    var card: CardTokens
    var sectionFrame: SectionFrameTokens
    var settingsPanel: SettingsPanelTokens
    var captionedRow: CaptionedRowTokens
    var codeBlock: CodeBlockTokens
    var modal: ModalTokens
    var drawer: DrawerTokens
    var confirmDialog: ConfirmDialogTokens
    var button: ButtonTokens
    var iconButton: IconButtonTokens
    var toggleButton: ToggleButtonTokens
    var appTile: AppTileTokens
    var chip: ChipTokens
    var swatchChip: SwatchChipTokens
    var badge: BadgeTokens
    var kbd: KbdTokens
    var modeSwitch: ModeSwitchTokens
    var basicShellHeader: BasicShellHeaderTokens
}

package struct AinkradComponentGroup2: Equatable, Sendable {
    var toggle: ToggleControlTokens
    var secureField: FieldControlTokens
    var textField: FieldControlTokens
    var searchField: FieldControlTokens
    var textArea: TextAreaTokens
    var slider: SliderTokens
    var formRow: FormRowTokens
    var stepper: StepperTokens
    var rangeSlider: SliderTokens
    var checkbox: CheckboxTokens
    var radioGroup: RadioGroupTokens
    var colorPicker: ColorPickerControlTokens
    var segmentedPicker: SegmentedPickerTokens
    var combobox: AinkradFieldRoleTokens
    var selectTrigger: AinkradTriggerRoleTokens
    var multiSelectTrigger: AinkradTriggerRoleTokens
    var groupedSelectTrigger: AinkradTriggerRoleTokens
    var multiSelectCheck: MultiSelectCheckTokens
    var groupedSelectRows: GroupedSelectRowTokens
}

package struct AinkradComponentGroup3: Equatable, Sendable {
    var contextMenu: ContextMenuTokens
    var tooltipPopover: TooltipPopoverTokens
    var commandMenuRow: CommandMenuRowTokens
    var navListRow: NavListRowTokens
    var tabs: TabsTokens
    var breadcrumb: BreadcrumbTokens
    var pagination: PaginationTokens
    var listRow: ListRowTokens
    var statRow: StatRowTokens
    var iconGlyph: IconGlyphTokens
    var dataTable: DataTableTokens
    var disclosureGroup: DisclosureGroupTokens
    var emptyState: EmptyStateTokens
    var loadingState: LoadingStateTokens
    var errorState: ErrorStateTokens
    var sectionHeader: SectionHeaderTokens
    var statusBar: StatusBarTokens
    var spinner: SpinnerTokens
    var meter: MeterTokens
    var stackedStatusBar: StackedStatusBarTokens
    var toast: ToastTokens
    var banner: BannerTokens
    var railItem: RailItemTokens
}

package struct AinkradComponentGroup4: Equatable, Sendable {
    var logView: LogViewTokens
    var signalFeedList: SignalFeedListTokens
    var signalFeedRow: SignalFeedRowTokens
    var signalFeedRowAction: SignalFeedRowActionTokens
    var signalSourceRail: SignalSourceRailTokens
    var signalToast: SignalToastTokens
    var settingsGroup: SettingsGroupTokens
    var settingsPage: SettingsPageTokens
    var settingsRow: SettingsRowTokens
    var label: LabelTokens
}
