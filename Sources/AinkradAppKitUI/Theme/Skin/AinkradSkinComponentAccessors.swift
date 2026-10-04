// design-lint: allow-file radius-literal,opacity-literal,frame-literal,chamfer-literal,motion-literal theme layer — component token aggregate struct
import Foundation

extension AinkradComponentTokens {
    public var panel: PanelTokens {
        get { storage.g1.panel }
        set { mutatingStorage().g1.panel = newValue }
    }
    public var card: CardTokens {
        get { storage.g1.card }
        set { mutatingStorage().g1.card = newValue }
    }
    public var sectionFrame: SectionFrameTokens {
        get { storage.g1.sectionFrame }
        set { mutatingStorage().g1.sectionFrame = newValue }
    }
    public var settingsPanel: SettingsPanelTokens {
        get { storage.g1.settingsPanel }
        set { mutatingStorage().g1.settingsPanel = newValue }
    }
    public var captionedRow: CaptionedRowTokens {
        get { storage.g1.captionedRow }
        set { mutatingStorage().g1.captionedRow = newValue }
    }
    public var codeBlock: CodeBlockTokens {
        get { storage.g1.codeBlock }
        set { mutatingStorage().g1.codeBlock = newValue }
    }
    public var modal: ModalTokens {
        get { storage.g1.modal }
        set { mutatingStorage().g1.modal = newValue }
    }
    public var drawer: DrawerTokens {
        get { storage.g1.drawer }
        set { mutatingStorage().g1.drawer = newValue }
    }
    public var confirmDialog: ConfirmDialogTokens {
        get { storage.g1.confirmDialog }
        set { mutatingStorage().g1.confirmDialog = newValue }
    }

    public var button: ButtonTokens {
        get { storage.g1.button }
        set { mutatingStorage().g1.button = newValue }
    }
    public var iconButton: IconButtonTokens {
        get { storage.g1.iconButton }
        set { mutatingStorage().g1.iconButton = newValue }
    }
    public var toggleButton: ToggleButtonTokens {
        get { storage.g1.toggleButton }
        set { mutatingStorage().g1.toggleButton = newValue }
    }
    public var appTile: AppTileTokens {
        get { storage.g1.appTile }
        set { mutatingStorage().g1.appTile = newValue }
    }
    public var chip: ChipTokens {
        get { storage.g1.chip }
        set { mutatingStorage().g1.chip = newValue }
    }
    public var swatchChip: SwatchChipTokens {
        get { storage.g1.swatchChip }
        set { mutatingStorage().g1.swatchChip = newValue }
    }
    public var badge: BadgeTokens {
        get { storage.g1.badge }
        set { mutatingStorage().g1.badge = newValue }
    }
    public var kbd: KbdTokens {
        get { storage.g1.kbd }
        set { mutatingStorage().g1.kbd = newValue }
    }
    public var modeSwitch: ModeSwitchTokens {
        get { storage.g1.modeSwitch }
        set { mutatingStorage().g1.modeSwitch = newValue }
    }
    public var basicShellHeader: BasicShellHeaderTokens {
        get { storage.g1.basicShellHeader }
        set { mutatingStorage().g1.basicShellHeader = newValue }
    }

    public var toggle: ToggleControlTokens {
        get { storage.g2.toggle }
        set { mutatingStorage().g2.toggle = newValue }
    }
    public var secureField: FieldControlTokens {
        get { storage.g2.secureField }
        set { mutatingStorage().g2.secureField = newValue }
    }
    public var textField: FieldControlTokens {
        get { storage.g2.textField }
        set { mutatingStorage().g2.textField = newValue }
    }
    public var searchField: FieldControlTokens {
        get { storage.g2.searchField }
        set { mutatingStorage().g2.searchField = newValue }
    }
    public var textArea: TextAreaTokens {
        get { storage.g2.textArea }
        set { mutatingStorage().g2.textArea = newValue }
    }
    public var slider: SliderTokens {
        get { storage.g2.slider }
        set { mutatingStorage().g2.slider = newValue }
    }
    public var formRow: FormRowTokens {
        get { storage.g2.formRow }
        set { mutatingStorage().g2.formRow = newValue }
    }
    public var stepper: StepperTokens {
        get { storage.g2.stepper }
        set { mutatingStorage().g2.stepper = newValue }
    }
    public var rangeSlider: SliderTokens {
        get { storage.g2.rangeSlider }
        set { mutatingStorage().g2.rangeSlider = newValue }
    }
    public var checkbox: CheckboxTokens {
        get { storage.g2.checkbox }
        set { mutatingStorage().g2.checkbox = newValue }
    }
    public var radioGroup: RadioGroupTokens {
        get { storage.g2.radioGroup }
        set { mutatingStorage().g2.radioGroup = newValue }
    }
    public var colorPicker: ColorPickerControlTokens {
        get { storage.g2.colorPicker }
        set { mutatingStorage().g2.colorPicker = newValue }
    }

    public var segmentedPicker: SegmentedPickerTokens {
        get { storage.g2.segmentedPicker }
        set { mutatingStorage().g2.segmentedPicker = newValue }
    }
    public var selectTrigger: AinkradTriggerRoleTokens {
        get { storage.g2.selectTrigger }
        set { mutatingStorage().g2.selectTrigger = newValue }
    }
    public var multiSelectTrigger: AinkradTriggerRoleTokens {
        get { storage.g2.multiSelectTrigger }
        set { mutatingStorage().g2.multiSelectTrigger = newValue }
    }
    public var groupedSelectTrigger: AinkradTriggerRoleTokens {
        get { storage.g2.groupedSelectTrigger }
        set { mutatingStorage().g2.groupedSelectTrigger = newValue }
    }
    public var combobox: AinkradFieldRoleTokens {
        get { storage.g2.combobox }
        set { mutatingStorage().g2.combobox = newValue }
    }
    public var multiSelectCheck: MultiSelectCheckTokens {
        get { storage.g2.multiSelectCheck }
        set { mutatingStorage().g2.multiSelectCheck = newValue }
    }
    public var groupedSelectRows: GroupedSelectRowTokens {
        get { storage.g2.groupedSelectRows }
        set { mutatingStorage().g2.groupedSelectRows = newValue }
    }
    public var contextMenu: ContextMenuTokens {
        get { storage.g3.contextMenu }
        set { mutatingStorage().g3.contextMenu = newValue }
    }
    public var tooltipPopover: TooltipPopoverTokens {
        get { storage.g3.tooltipPopover }
        set { mutatingStorage().g3.tooltipPopover = newValue }
    }
    public var commandMenuRow: CommandMenuRowTokens {
        get { storage.g3.commandMenuRow }
        set { mutatingStorage().g3.commandMenuRow = newValue }
    }
    public var navListRow: NavListRowTokens {
        get { storage.g3.navListRow }
        set { mutatingStorage().g3.navListRow = newValue }
    }
    public var tabs: TabsTokens {
        get { storage.g3.tabs }
        set { mutatingStorage().g3.tabs = newValue }
    }
    public var breadcrumb: BreadcrumbTokens {
        get { storage.g3.breadcrumb }
        set { mutatingStorage().g3.breadcrumb = newValue }
    }
    public var pagination: PaginationTokens {
        get { storage.g3.pagination }
        set { mutatingStorage().g3.pagination = newValue }
    }

    public var listRow: ListRowTokens {
        get { storage.g3.listRow }
        set { mutatingStorage().g3.listRow = newValue }
    }
    public var statRow: StatRowTokens {
        get { storage.g3.statRow }
        set { mutatingStorage().g3.statRow = newValue }
    }
    public var iconGlyph: IconGlyphTokens {
        get { storage.g3.iconGlyph }
        set { mutatingStorage().g3.iconGlyph = newValue }
    }
    public var dataTable: DataTableTokens {
        get { storage.g3.dataTable }
        set { mutatingStorage().g3.dataTable = newValue }
    }
    public var disclosureGroup: DisclosureGroupTokens {
        get { storage.g3.disclosureGroup }
        set { mutatingStorage().g3.disclosureGroup = newValue }
    }
    public var emptyState: EmptyStateTokens {
        get { storage.g3.emptyState }
        set { mutatingStorage().g3.emptyState = newValue }
    }
    public var loadingState: LoadingStateTokens {
        get { storage.g3.loadingState }
        set { mutatingStorage().g3.loadingState = newValue }
    }
    public var errorState: ErrorStateTokens {
        get { storage.g3.errorState }
        set { mutatingStorage().g3.errorState = newValue }
    }
    public var sectionHeader: SectionHeaderTokens {
        get { storage.g3.sectionHeader }
        set { mutatingStorage().g3.sectionHeader = newValue }
    }
    public var statusBar: StatusBarTokens {
        get { storage.g3.statusBar }
        set { mutatingStorage().g3.statusBar = newValue }
    }
    public var spinner: SpinnerTokens {
        get { storage.g3.spinner }
        set { mutatingStorage().g3.spinner = newValue }
    }
    public var meter: MeterTokens {
        get { storage.g3.meter }
        set { mutatingStorage().g3.meter = newValue }
    }
    public var stackedStatusBar: StackedStatusBarTokens {
        get { storage.g3.stackedStatusBar }
        set { mutatingStorage().g3.stackedStatusBar = newValue }
    }
    public var toast: ToastTokens {
        get { storage.g3.toast }
        set { mutatingStorage().g3.toast = newValue }
    }
    public var banner: BannerTokens {
        get { storage.g3.banner }
        set { mutatingStorage().g3.banner = newValue }
    }

    public var logView: LogViewTokens {
        get { storage.g4.logView }
        set { mutatingStorage().g4.logView = newValue }
    }

    public var signalFeedList: SignalFeedListTokens {
        get { storage.g4.signalFeedList }
        set { mutatingStorage().g4.signalFeedList = newValue }
    }
    public var signalFeedRow: SignalFeedRowTokens {
        get { storage.g4.signalFeedRow }
        set { mutatingStorage().g4.signalFeedRow = newValue }
    }
    public var signalFeedRowAction: SignalFeedRowActionTokens {
        get { storage.g4.signalFeedRowAction }
        set { mutatingStorage().g4.signalFeedRowAction = newValue }
    }
    public var signalSourceRail: SignalSourceRailTokens {
        get { storage.g4.signalSourceRail }
        set { mutatingStorage().g4.signalSourceRail = newValue }
    }
    public var signalToast: SignalToastTokens {
        get { storage.g4.signalToast }
        set { mutatingStorage().g4.signalToast = newValue }
    }

    public var settingsGroup: SettingsGroupTokens {
        get { storage.g4.settingsGroup }
        set { mutatingStorage().g4.settingsGroup = newValue }
    }
    public var settingsPage: SettingsPageTokens {
        get { storage.g4.settingsPage }
        set { mutatingStorage().g4.settingsPage = newValue }
    }
    public var settingsRow: SettingsRowTokens {
        get { storage.g4.settingsRow }
        set { mutatingStorage().g4.settingsRow = newValue }
    }
}
