// design-lint: allow-file radius-literal,opacity-literal,frame-literal,chamfer-literal,motion-literal theme layer — component token aggregate struct
import Foundation

public struct AinkradComponentTokens: Codable, Equatable, Sendable {
    private final class Storage: Codable, Equatable, @unchecked Sendable {
        var g1: AinkradComponentGroup1
        var g2: AinkradComponentGroup2
        var g3: AinkradComponentGroup3
        var g4: AinkradComponentGroup4

        init(
            g1: AinkradComponentGroup1, g2: AinkradComponentGroup2, g3: AinkradComponentGroup3,
            g4: AinkradComponentGroup4
        ) {
            self.g1 = g1
            self.g2 = g2
            self.g3 = g3
            self.g4 = g4
        }

        static func == (lhs: Storage, rhs: Storage) -> Bool {
            lhs === rhs || (lhs.g1 == rhs.g1 && lhs.g2 == rhs.g2 && lhs.g3 == rhs.g3 && lhs.g4 == rhs.g4)
        }

        enum CodingKeys: String, CodingKey {
            case panel, card, sectionFrame, settingsPanel, captionedRow, codeBlock, modal, drawer, confirmDialog
            case button, iconButton, toggleButton, appTile, chip, swatchChip, badge, kbd, modeSwitch, basicShellHeader
            case toggle, secureField, textField, searchField, textArea, slider, formRow, stepper, rangeSlider
            case checkbox, radioGroup, colorPicker, segmentedPicker, combobox, selectTrigger, multiSelectTrigger,
                groupedSelectTrigger
            case multiSelectCheck, groupedSelectRows, contextMenu, tooltipPopover, commandMenuRow, navListRow, tabs
            case breadcrumb, pagination, listRow, statRow, iconGlyph, dataTable, disclosureGroup, emptyState
            case loadingState, errorState, sectionHeader, statusBar, spinner, meter, stackedStatusBar, toast, banner
            case logView, signalFeedList, signalFeedRow, signalFeedRowAction, signalSourceRail, signalToast
            case settingsGroup, settingsPage, settingsRow
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let g1 = AinkradComponentGroup1(
                panel: try container.decode(PanelTokens.self, forKey: .panel),
                card: try container.decode(CardTokens.self, forKey: .card),
                sectionFrame: try container.decode(SectionFrameTokens.self, forKey: .sectionFrame),
                settingsPanel: try container.decode(SettingsPanelTokens.self, forKey: .settingsPanel),
                captionedRow: try container.decode(CaptionedRowTokens.self, forKey: .captionedRow),
                codeBlock: try container.decode(CodeBlockTokens.self, forKey: .codeBlock),
                modal: try container.decode(ModalTokens.self, forKey: .modal),
                drawer: try container.decode(DrawerTokens.self, forKey: .drawer),
                confirmDialog: try container.decode(ConfirmDialogTokens.self, forKey: .confirmDialog),
                button: try container.decode(ButtonTokens.self, forKey: .button),
                iconButton: try container.decode(IconButtonTokens.self, forKey: .iconButton),
                toggleButton: try container.decode(ToggleButtonTokens.self, forKey: .toggleButton),
                appTile: try container.decode(AppTileTokens.self, forKey: .appTile),
                chip: try container.decode(ChipTokens.self, forKey: .chip),
                swatchChip: try container.decode(SwatchChipTokens.self, forKey: .swatchChip),
                badge: try container.decode(BadgeTokens.self, forKey: .badge),
                kbd: try container.decode(KbdTokens.self, forKey: .kbd),
                modeSwitch: try container.decode(ModeSwitchTokens.self, forKey: .modeSwitch),
                basicShellHeader: try container.decode(BasicShellHeaderTokens.self, forKey: .basicShellHeader)
            )
            let g2 = AinkradComponentGroup2(
                toggle: try container.decode(ToggleControlTokens.self, forKey: .toggle),
                secureField: try container.decode(FieldControlTokens.self, forKey: .secureField),
                textField: try container.decode(FieldControlTokens.self, forKey: .textField),
                searchField: try container.decode(FieldControlTokens.self, forKey: .searchField),
                textArea: try container.decode(TextAreaTokens.self, forKey: .textArea),
                slider: try container.decode(SliderTokens.self, forKey: .slider),
                formRow: try container.decode(FormRowTokens.self, forKey: .formRow),
                stepper: try container.decode(StepperTokens.self, forKey: .stepper),
                rangeSlider: try container.decode(SliderTokens.self, forKey: .rangeSlider),
                checkbox: try container.decode(CheckboxTokens.self, forKey: .checkbox),
                radioGroup: try container.decode(RadioGroupTokens.self, forKey: .radioGroup),
                colorPicker: try container.decode(ColorPickerControlTokens.self, forKey: .colorPicker),
                segmentedPicker: try container.decode(SegmentedPickerTokens.self, forKey: .segmentedPicker),
                combobox: try container.decode(AinkradFieldRoleTokens.self, forKey: .combobox),
                selectTrigger: try container.decode(AinkradTriggerRoleTokens.self, forKey: .selectTrigger),
                multiSelectTrigger: try container.decode(AinkradTriggerRoleTokens.self, forKey: .multiSelectTrigger),
                groupedSelectTrigger: try container.decode(
                    AinkradTriggerRoleTokens.self, forKey: .groupedSelectTrigger),
                multiSelectCheck: try container.decode(MultiSelectCheckTokens.self, forKey: .multiSelectCheck),
                groupedSelectRows: try container.decode(GroupedSelectRowTokens.self, forKey: .groupedSelectRows)
            )
            let g3 = AinkradComponentGroup3(
                contextMenu: try container.decode(ContextMenuTokens.self, forKey: .contextMenu),
                tooltipPopover: try container.decode(TooltipPopoverTokens.self, forKey: .tooltipPopover),
                commandMenuRow: try container.decode(CommandMenuRowTokens.self, forKey: .commandMenuRow),
                navListRow: try container.decode(NavListRowTokens.self, forKey: .navListRow),
                tabs: try container.decode(TabsTokens.self, forKey: .tabs),
                breadcrumb: try container.decode(BreadcrumbTokens.self, forKey: .breadcrumb),
                pagination: try container.decode(PaginationTokens.self, forKey: .pagination),
                listRow: try container.decode(ListRowTokens.self, forKey: .listRow),
                statRow: try container.decode(StatRowTokens.self, forKey: .statRow),
                iconGlyph: try container.decode(IconGlyphTokens.self, forKey: .iconGlyph),
                dataTable: try container.decode(DataTableTokens.self, forKey: .dataTable),
                disclosureGroup: try container.decode(DisclosureGroupTokens.self, forKey: .disclosureGroup),
                emptyState: try container.decode(EmptyStateTokens.self, forKey: .emptyState),
                loadingState: try container.decode(LoadingStateTokens.self, forKey: .loadingState),
                errorState: try container.decode(ErrorStateTokens.self, forKey: .errorState),
                sectionHeader: try container.decode(SectionHeaderTokens.self, forKey: .sectionHeader),
                statusBar: try container.decode(StatusBarTokens.self, forKey: .statusBar),
                spinner: try container.decode(SpinnerTokens.self, forKey: .spinner),
                meter: try container.decode(MeterTokens.self, forKey: .meter),
                stackedStatusBar: try container.decode(StackedStatusBarTokens.self, forKey: .stackedStatusBar),
                toast: try container.decode(ToastTokens.self, forKey: .toast),
                banner: try container.decode(BannerTokens.self, forKey: .banner)
            )
            let g4 = AinkradComponentGroup4(
                logView: try container.decode(LogViewTokens.self, forKey: .logView),
                signalFeedList: try container.decode(SignalFeedListTokens.self, forKey: .signalFeedList),
                signalFeedRow: try container.decode(SignalFeedRowTokens.self, forKey: .signalFeedRow),
                signalFeedRowAction: try container.decode(SignalFeedRowActionTokens.self, forKey: .signalFeedRowAction),
                signalSourceRail: try container.decode(SignalSourceRailTokens.self, forKey: .signalSourceRail),
                signalToast: try container.decode(SignalToastTokens.self, forKey: .signalToast),
                settingsGroup: try container.decode(SettingsGroupTokens.self, forKey: .settingsGroup),
                settingsPage: try container.decode(SettingsPageTokens.self, forKey: .settingsPage),
                settingsRow: try container.decode(SettingsRowTokens.self, forKey: .settingsRow)
            )
            self.g1 = g1
            self.g2 = g2
            self.g3 = g3
            self.g4 = g4
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(g1.panel, forKey: .panel)
            try container.encode(g1.card, forKey: .card)
            try container.encode(g1.sectionFrame, forKey: .sectionFrame)
            try container.encode(g1.settingsPanel, forKey: .settingsPanel)
            try container.encode(g1.captionedRow, forKey: .captionedRow)
            try container.encode(g1.codeBlock, forKey: .codeBlock)
            try container.encode(g1.modal, forKey: .modal)
            try container.encode(g1.drawer, forKey: .drawer)
            try container.encode(g1.confirmDialog, forKey: .confirmDialog)
            try container.encode(g1.button, forKey: .button)
            try container.encode(g1.iconButton, forKey: .iconButton)
            try container.encode(g1.toggleButton, forKey: .toggleButton)
            try container.encode(g1.appTile, forKey: .appTile)
            try container.encode(g1.chip, forKey: .chip)
            try container.encode(g1.swatchChip, forKey: .swatchChip)
            try container.encode(g1.badge, forKey: .badge)
            try container.encode(g1.kbd, forKey: .kbd)
            try container.encode(g1.modeSwitch, forKey: .modeSwitch)
            try container.encode(g1.basicShellHeader, forKey: .basicShellHeader)

            try container.encode(g2.toggle, forKey: .toggle)
            try container.encode(g2.secureField, forKey: .secureField)
            try container.encode(g2.textField, forKey: .textField)
            try container.encode(g2.searchField, forKey: .searchField)
            try container.encode(g2.textArea, forKey: .textArea)
            try container.encode(g2.slider, forKey: .slider)
            try container.encode(g2.formRow, forKey: .formRow)
            try container.encode(g2.stepper, forKey: .stepper)
            try container.encode(g2.rangeSlider, forKey: .rangeSlider)
            try container.encode(g2.checkbox, forKey: .checkbox)
            try container.encode(g2.radioGroup, forKey: .radioGroup)
            try container.encode(g2.colorPicker, forKey: .colorPicker)
            try container.encode(g2.segmentedPicker, forKey: .segmentedPicker)
            try container.encode(g2.combobox, forKey: .combobox)
            try container.encode(g2.selectTrigger, forKey: .selectTrigger)
            try container.encode(g2.multiSelectTrigger, forKey: .multiSelectTrigger)
            try container.encode(g2.groupedSelectTrigger, forKey: .groupedSelectTrigger)
            try container.encode(g2.multiSelectCheck, forKey: .multiSelectCheck)
            try container.encode(g2.groupedSelectRows, forKey: .groupedSelectRows)

            try container.encode(g3.contextMenu, forKey: .contextMenu)
            try container.encode(g3.tooltipPopover, forKey: .tooltipPopover)
            try container.encode(g3.commandMenuRow, forKey: .commandMenuRow)
            try container.encode(g3.navListRow, forKey: .navListRow)
            try container.encode(g3.tabs, forKey: .tabs)
            try container.encode(g3.breadcrumb, forKey: .breadcrumb)
            try container.encode(g3.pagination, forKey: .pagination)
            try container.encode(g3.listRow, forKey: .listRow)
            try container.encode(g3.statRow, forKey: .statRow)
            try container.encode(g3.iconGlyph, forKey: .iconGlyph)
            try container.encode(g3.dataTable, forKey: .dataTable)
            try container.encode(g3.disclosureGroup, forKey: .disclosureGroup)
            try container.encode(g3.emptyState, forKey: .emptyState)
            try container.encode(g3.loadingState, forKey: .loadingState)
            try container.encode(g3.errorState, forKey: .errorState)
            try container.encode(g3.sectionHeader, forKey: .sectionHeader)
            try container.encode(g3.statusBar, forKey: .statusBar)
            try container.encode(g3.spinner, forKey: .spinner)
            try container.encode(g3.meter, forKey: .meter)
            try container.encode(g3.stackedStatusBar, forKey: .stackedStatusBar)
            try container.encode(g3.toast, forKey: .toast)
            try container.encode(g3.banner, forKey: .banner)

            try container.encode(g4.logView, forKey: .logView)
            try container.encode(g4.signalFeedList, forKey: .signalFeedList)
            try container.encode(g4.signalFeedRow, forKey: .signalFeedRow)
            try container.encode(g4.signalFeedRowAction, forKey: .signalFeedRowAction)
            try container.encode(g4.signalSourceRail, forKey: .signalSourceRail)
            try container.encode(g4.signalToast, forKey: .signalToast)
            try container.encode(g4.settingsGroup, forKey: .settingsGroup)
            try container.encode(g4.settingsPage, forKey: .settingsPage)
            try container.encode(g4.settingsRow, forKey: .settingsRow)
        }
    }

    private var storage: Storage

    public init(from decoder: Decoder) throws {
        self.storage = try Storage(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        try storage.encode(to: encoder)
    }

    public static func == (lhs: AinkradComponentTokens, rhs: AinkradComponentTokens) -> Bool {
        lhs.storage == rhs.storage
    }

    package init(
        g1: AinkradComponentGroup1, g2: AinkradComponentGroup2, g3: AinkradComponentGroup3, g4: AinkradComponentGroup4
    ) {
        self.storage = Storage(g1: g1, g2: g2, g3: g3, g4: g4)
    }

    public init(
        panel: PanelTokens, card: CardTokens, sectionFrame: SectionFrameTokens,
        settingsPanel: SettingsPanelTokens, captionedRow: CaptionedRowTokens, codeBlock: CodeBlockTokens,
        modal: ModalTokens, drawer: DrawerTokens, confirmDialog: ConfirmDialogTokens,
        button: ButtonTokens, iconButton: IconButtonTokens, toggleButton: ToggleButtonTokens,
        appTile: AppTileTokens, chip: ChipTokens, swatchChip: SwatchChipTokens,
        badge: BadgeTokens, kbd: KbdTokens, modeSwitch: ModeSwitchTokens, basicShellHeader: BasicShellHeaderTokens,
        toggle: ToggleControlTokens, secureField: FieldControlTokens, textField: FieldControlTokens,
        searchField: FieldControlTokens, textArea: TextAreaTokens, slider: SliderTokens,
        formRow: FormRowTokens, stepper: StepperTokens, rangeSlider: SliderTokens,
        checkbox: CheckboxTokens, radioGroup: RadioGroupTokens, colorPicker: ColorPickerControlTokens,
        segmentedPicker: SegmentedPickerTokens, selectTrigger: AinkradTriggerRoleTokens,
        multiSelectTrigger: AinkradTriggerRoleTokens, groupedSelectTrigger: AinkradTriggerRoleTokens,
        combobox: AinkradFieldRoleTokens, multiSelectCheck: MultiSelectCheckTokens,
        groupedSelectRows: GroupedSelectRowTokens,
        contextMenu: ContextMenuTokens, tooltipPopover: TooltipPopoverTokens, commandMenuRow: CommandMenuRowTokens,
        navListRow: NavListRowTokens, tabs: TabsTokens, breadcrumb: BreadcrumbTokens,
        pagination: PaginationTokens, listRow: ListRowTokens, statRow: StatRowTokens,
        iconGlyph: IconGlyphTokens, dataTable: DataTableTokens, disclosureGroup: DisclosureGroupTokens,
        emptyState: EmptyStateTokens, loadingState: LoadingStateTokens, errorState: ErrorStateTokens,
        sectionHeader: SectionHeaderTokens, statusBar: StatusBarTokens, spinner: SpinnerTokens,
        meter: MeterTokens, stackedStatusBar: StackedStatusBarTokens, toast: ToastTokens, banner: BannerTokens,
        logView: LogViewTokens, signalFeedList: SignalFeedListTokens, signalFeedRow: SignalFeedRowTokens,
        signalFeedRowAction: SignalFeedRowActionTokens, signalSourceRail: SignalSourceRailTokens,
        signalToast: SignalToastTokens,
        settingsGroup: SettingsGroupTokens, settingsPage: SettingsPageTokens, settingsRow: SettingsRowTokens
    ) {
        let g1 = AinkradComponentGroup1(
            panel: panel, card: card, sectionFrame: sectionFrame, settingsPanel: settingsPanel,
            captionedRow: captionedRow, codeBlock: codeBlock, modal: modal, drawer: drawer,
            confirmDialog: confirmDialog, button: button, iconButton: iconButton, toggleButton: toggleButton,
            appTile: appTile, chip: chip, swatchChip: swatchChip, badge: badge, kbd: kbd,
            modeSwitch: modeSwitch, basicShellHeader: basicShellHeader
        )
        let g2 = AinkradComponentGroup2(
            toggle: toggle, secureField: secureField, textField: textField, searchField: searchField,
            textArea: textArea, slider: slider, formRow: formRow, stepper: stepper,
            rangeSlider: rangeSlider, checkbox: checkbox, radioGroup: radioGroup, colorPicker: colorPicker,
            segmentedPicker: segmentedPicker, combobox: combobox, selectTrigger: selectTrigger,
            multiSelectTrigger: multiSelectTrigger, groupedSelectTrigger: groupedSelectTrigger,
            multiSelectCheck: multiSelectCheck, groupedSelectRows: groupedSelectRows
        )
        let g3 = AinkradComponentGroup3(
            contextMenu: contextMenu, tooltipPopover: tooltipPopover, commandMenuRow: commandMenuRow,
            navListRow: navListRow, tabs: tabs, breadcrumb: breadcrumb, pagination: pagination,
            listRow: listRow, statRow: statRow, iconGlyph: iconGlyph, dataTable: dataTable,
            disclosureGroup: disclosureGroup, emptyState: emptyState, loadingState: loadingState,
            errorState: errorState, sectionHeader: sectionHeader, statusBar: statusBar, spinner: spinner,
            meter: meter, stackedStatusBar: stackedStatusBar, toast: toast, banner: banner
        )
        let g4 = AinkradComponentGroup4(
            logView: logView, signalFeedList: signalFeedList, signalFeedRow: signalFeedRow,
            signalFeedRowAction: signalFeedRowAction, signalSourceRail: signalSourceRail, signalToast: signalToast,
            settingsGroup: settingsGroup, settingsPage: settingsPage, settingsRow: settingsRow
        )
        self.storage = Storage(g1: g1, g2: g2, g3: g3, g4: g4)
    }

    private mutating func mutatingStorage() -> Storage {
        if !isKnownUniquelyReferenced(&storage) {
            self.storage = Storage(g1: storage.g1, g2: storage.g2, g3: storage.g3, g4: storage.g4)
        }
        return storage
    }

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
