import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import PresentationDataUtils
import AccountContext

// MARK: - Joker Settings Controller
// شاشة إعدادات تعديلات الجوكر (Talogram) — تفعيل/تعطيل جميع المميزات
// مكتوبة بالنمط الحديث (function factory) المطابق لواجهات ItemListUI الحالية

private final class JokerSettingsControllerArguments {
    let updateAutoSaveMedia: (Bool) -> Void
    let updateAllow100Accounts: (Bool) -> Void
    let updateGhostMode: (Bool) -> Void
    let updateForcePremiumTranslation: (Bool) -> Void
    let updateKeepDeletedMessages: (Bool) -> Void
    let updateFreezeLastSeen: (Bool) -> Void
    let updateBypassCopyProtection: (Bool) -> Void
    let updateRequireSubscription: (Bool) -> Void
    let openChannel: () -> Void
    
    init(
        updateAutoSaveMedia: @escaping (Bool) -> Void,
        updateAllow100Accounts: @escaping (Bool) -> Void,
        updateGhostMode: @escaping (Bool) -> Void,
        updateForcePremiumTranslation: @escaping (Bool) -> Void,
        updateKeepDeletedMessages: @escaping (Bool) -> Void,
        updateFreezeLastSeen: @escaping (Bool) -> Void,
        updateBypassCopyProtection: @escaping (Bool) -> Void,
        updateRequireSubscription: @escaping (Bool) -> Void,
        openChannel: @escaping () -> Void
    ) {
        self.updateAutoSaveMedia = updateAutoSaveMedia
        self.updateAllow100Accounts = updateAllow100Accounts
        self.updateGhostMode = updateGhostMode
        self.updateForcePremiumTranslation = updateForcePremiumTranslation
        self.updateKeepDeletedMessages = updateKeepDeletedMessages
        self.updateFreezeLastSeen = updateFreezeLastSeen
        self.updateBypassCopyProtection = updateBypassCopyProtection
        self.updateRequireSubscription = updateRequireSubscription
        self.openChannel = openChannel
    }
}

private enum JokerSettingsControllerSection: Int32 {
    case channelSubscription
    case features
    case credits
}

// نص ثنائي اللغة: يُستخدم لأن مفاتيح الجوكر غير موجودة في حزم اللغات البعيدة،
// فيظهر العربي عند استخدام لغة عربية والإنجليزية في أي لغة أخرى.
private func jokerLocalized(_ presentationData: PresentationData, _ arValue: String, _ enValue: String) -> String {
    return jokerLocalize(sample: presentationData.strings.Common_Back, arValue: arValue, enValue: enValue)
}

private enum JokerSettingsControllerEntry: ItemListNodeEntry {
    case channelSubscriptionHeader(String)
    case channelSubscriptionInfo(String)
    case channelSubscribeButton(String)
    
    case featuresHeader(String)
    case autoSaveMediaToggle(String, String, Bool)
    case allow100AccountsToggle(String, String, Bool)
    case ghostModeToggle(String, String, Bool)
    case forcePremiumTranslationToggle(String, String, Bool)
    case freezeLastSeenToggle(String, String, Bool)
    case bypassCopyProtectionToggle(String, String, Bool)
    case keepDeletedMessagesToggle(String, String, Bool)
    case requireSubscriptionToggle(String, String, Bool)
    
    case creditsHeader(String)
    case creditsText(String)
    
    var section: ItemListSectionId {
        switch self {
        case .channelSubscriptionHeader, .channelSubscriptionInfo, .channelSubscribeButton:
            return JokerSettingsControllerSection.channelSubscription.rawValue
        case .featuresHeader, .autoSaveMediaToggle, .allow100AccountsToggle, .ghostModeToggle, .forcePremiumTranslationToggle, .freezeLastSeenToggle, .bypassCopyProtectionToggle, .keepDeletedMessagesToggle, .requireSubscriptionToggle:
            return JokerSettingsControllerSection.features.rawValue
        case .creditsHeader, .creditsText:
            return JokerSettingsControllerSection.credits.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case .channelSubscriptionHeader:
            return 0
        case .channelSubscriptionInfo:
            return 1
        case .channelSubscribeButton:
            return 2
        case .featuresHeader:
            return 10
        case .autoSaveMediaToggle:
            return 11
        case .allow100AccountsToggle:
            return 12
        case .ghostModeToggle:
            return 13
        case .forcePremiumTranslationToggle:
            return 14
        case .freezeLastSeenToggle:
            return 15
        case .bypassCopyProtectionToggle:
            return 16
        case .keepDeletedMessagesToggle:
            return 17
        case .requireSubscriptionToggle:
            return 18
        case .creditsHeader:
            return 20
        case .creditsText:
            return 21
        }
    }
    
    static func <(lhs: JokerSettingsControllerEntry, rhs: JokerSettingsControllerEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! JokerSettingsControllerArguments
        switch self {
        case let .channelSubscriptionHeader(title):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: title, sectionId: self.section)
        case let .channelSubscriptionInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .markdown(text), sectionId: self.section)
        case let .channelSubscribeButton(title):
            return ItemListActionItem(presentationData: presentationData, title: title, kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                arguments.openChannel()
            })
        case let .featuresHeader(title):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: title, sectionId: self.section)
        case let .autoSaveMediaToggle(title, text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, text: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateAutoSaveMedia(value)
            })
        case let .allow100AccountsToggle(title, text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, text: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateAllow100Accounts(value)
            })
        case let .ghostModeToggle(title, text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, text: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateGhostMode(value)
            })
        case let .forcePremiumTranslationToggle(title, text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, text: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateForcePremiumTranslation(value)
            })
        case let .freezeLastSeenToggle(title, text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, text: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateFreezeLastSeen(value)
            })
        case let .bypassCopyProtectionToggle(title, text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, text: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateBypassCopyProtection(value)
            })
        case let .keepDeletedMessagesToggle(title, text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, text: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateKeepDeletedMessages(value)
            })
        case let .requireSubscriptionToggle(title, text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, text: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateRequireSubscription(value)
            })
        case let .creditsHeader(title):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: title, sectionId: self.section)
        case let .creditsText(text):
            return ItemListTextItem(presentationData: presentationData, text: .markdown(text), sectionId: self.section)
        }
    }
}

private func jokerSettingsControllerEntries(presentationData: PresentationData, settings: JokerSettings) -> [JokerSettingsControllerEntry] {
    var entries: [JokerSettingsControllerEntry] = []
    
    // القسم الأول: الاشتراك في القناة
    entries.append(.channelSubscriptionHeader(jokerLocalized(presentationData, "الاشتراك في القناة", "Channel Subscription")))
    entries.append(.channelSubscriptionInfo(jokerLocalized(presentationData, "يجب الاشتراك في قناة @aljokeruserbot لتفعيل مميزات الجوكر.", "You must subscribe to @aljokeruserbot channel to enable Joker features.")))
    entries.append(.channelSubscribeButton(jokerLocalized(presentationData, "الاشتراك في القناة", "Subscribe to Channel")))
    
    // القسم الثاني: المميزات
    entries.append(.featuresHeader(jokerLocalized(presentationData, "مميزات الجوكر", "Joker Features")))
    entries.append(.autoSaveMediaToggle(jokerLocalized(presentationData, "حفظ الوسائط ذاتية التدمير تلقائياً", "Auto Save Self-Destructing Media"), jokerLocalized(presentationData, "حفظ الصور والفيديوهات والرسائل الصوتية ذاتية التدمير في الرسائل المحفوظة تلقائياً عند فتحها.", "Automatically save self-destructing photos, videos, and voice messages to Saved Messages when opened."), settings.autoSaveSelfDestructingMedia))
    entries.append(.allow100AccountsToggle(jokerLocalized(presentationData, "السماح حتى 100 حساب", "Allow 100 Accounts"), jokerLocalized(presentationData, "السماح بإضافة حتى 100 حساب في التطبيق.", "Allow adding up to 100 accounts in the app."), settings.allow100Accounts))
    entries.append(.ghostModeToggle(jokerLocalized(presentationData, "وضع الشبح", "Ghost Mode"), jokerLocalized(presentationData, "إخفاء علامات قراءة الرسائل. إضافة أيقونة عين على الرسالة، اضغط عليها لتحديدها كمقروءة.", "Hide read receipts. Add an eye icon to messages - tap to mark as read."), settings.ghostMode))
    entries.append(.forcePremiumTranslationToggle(jokerLocalized(presentationData, "ترجمة البريميوم مجاناً", "Force Premium Translation"), jokerLocalized(presentationData, "تفعيل ميزة الترجمة الخاصة بالبريميوم مجاناً في المحادثات والقنوات.", "Enable the Premium translation feature for free in chats and channels."), settings.forcePremiumTranslation))
    entries.append(.freezeLastSeenToggle(jokerLocalized(presentationData, "تجميد آخر ظهور", "Freeze Last Seen"), jokerLocalized(presentationData, "إخفاء حالة آخر ظهور الخاصة بك وعدم إرسال تحديثات الحضور إلى الخادم.", "Hide your last seen status and stop sending presence updates to the server."), settings.freezeLastSeen))
    entries.append(.bypassCopyProtectionToggle(jokerLocalized(presentationData, "تجاوز حماية المحتوى", "Bypass Copy Protection"), jokerLocalized(presentationData, "تجاوز قيود حماية النسخ في القنوات المحمية: نسخ caption، وحفظ الصور، وإعادة توجيه الرسالة بالكامل (الصورة مع caption).", "Bypass copy protection in protected channels: copy captions, save images, and forward the full message (image with caption)."), settings.bypassCopyProtection))
    entries.append(.keepDeletedMessagesToggle(jokerLocalized(presentationData, "الاحتفاظ بالرسائل المحذوفة", "Keep Deleted Messages"), jokerLocalized(presentationData, "الاحتفاظ بالرسائل المحذوفة محلياً مع علامة x بجانب الفقاعة. مسح المحادثة يحذف كل شيء نهائياً.", "Keep deleted messages locally with an 'x' mark next to the bubble. Clearing history deletes everything permanently."), settings.keepDeletedMessages))
    entries.append(.requireSubscriptionToggle(jokerLocalized(presentationData, "اشتراط الاشتراك في القناة", "Require Channel Subscription"), jokerLocalized(presentationData, "مطالبة بالاشتراك في قناة @aljokeruserbot قبل تفعيل أي ميزة من مميزات الجوكر.", "Require subscription to @aljokeruserbot channel before enabling any Joker feature."), settings.requireChannelSubscription))
    
    // القسم الثالث: الحقوق
    entries.append(.creditsHeader(jokerLocalized(presentationData, "حقوق المصدر", "Source Credits")))
    entries.append(.creditsText(jokerLocalized(presentationData, "إصدار معدّل من Talogram - المصدر بواسطة @aljokeruserbot", "Talogram Modified Version - Source by @aljokeruserbot")))
    
    return entries
}

public func jokerSettingsController(context: AccountContext) -> ViewController {
    var openChannelImpl: (() -> Void)? = nil
    
    let arguments = JokerSettingsControllerArguments(
        updateAutoSaveMedia: { value in
            let _ = updateJokerSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedAutoSaveSelfDestructingMedia(value) }).start()
        },
        updateAllow100Accounts: { value in
            let _ = updateJokerSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedAllow100Accounts(value) }).start()
        },
        updateGhostMode: { value in
            let _ = updateJokerSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedGhostMode(value) }).start()
        },
        updateForcePremiumTranslation: { value in
            let _ = updateJokerSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedForcePremiumTranslation(value) }).start()
        },
        updateKeepDeletedMessages: { value in
            let _ = updateJokerSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedKeepDeletedMessages(value) }).start()
        },
        updateFreezeLastSeen: { value in
            let _ = updateJokerSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedFreezeLastSeen(value) }).start()
        },
        updateBypassCopyProtection: { value in
            let _ = updateJokerSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedBypassCopyProtection(value) }).start()
        },
        updateRequireSubscription: { value in
            let _ = updateJokerSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedRequireChannelSubscription(value) }).start()
        },
        openChannel: {
            openChannelImpl?()
        }
    )
    
    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        getJokerSettings(accountManager: context.sharedContext.accountManager)
    )
    |> deliverOnMainQueue
    |> map { presentationData, jokerSettings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        var presentationData = presentationData
        
        let updatedTheme = presentationData.theme.withModalBlocksBackground()
        presentationData = presentationData.withUpdated(theme: updatedTheme)
        
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(jokerLocalized(presentationData, "إعدادات الجوكر", "Joker Settings")), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: jokerSettingsControllerEntries(presentationData: presentationData, settings: jokerSettings), style: .blocks, animateChanges: true)
        
        return (controllerState, (listState, arguments))
    }
    
    let controller = ItemListController(context: context, state: signal)
    controller.navigationPresentation = .modal
    
    openChannelImpl = { [weak controller] in
        guard let controller, let navigationController = controller.navigationController as? NavigationController else {
            return
        }
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        context.sharedContext.openExternalUrl(context: context, urlContext: .generic, url: JokerChannelSubscriptionManager.channelLink, forceExternal: false, presentationData: presentationData, navigationController: navigationController, dismissInput: {
        })
    }
    
    return controller
}
