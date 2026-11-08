import Foundation
import UIKit
import TelegramCore
import SwiftSignalKit
import AsyncDisplayKit
import TelegramUIPreferences
import AccountContext
import TelegramPresentationData

// MARK: - Joker Integration Manager
// هذا الملف يربط مميزات الجوكر مع الكود الأصلي للتليجرام
// تم نقله إلى وحدة ChatMessageBubbleItemNode لأن اعتماداته متوفرة هناك.
// ملاحظة: لا يُستورد Postbox هنا (بوابة PostboxImportCheck)، وأنواع الوسائط
// تُمرَّر عبر واجهات TelegramEngine عند التفعيل الفعلي لاحقاً.

public class JokerIntegrationManager {

    // MARK: - ميزة 1: حفظ الوسائط ذاتية التدمير تلقائياً
    // استدع هذه الدالة عند فتح أي وسائط ذاتية التدمير في العارض
    public static func onMediaOpened(context: AccountContext, messageId: EngineMessage.Id?) {
        guard let messageId = messageId else { return }
        guard isAutoSaveMediaAllowed() else { return }
        let _ = JokerCoreHooks.saveConsumedMediaIfNeeded(account: context.account, messageId: messageId).start()
    }

    // بوابة الاشتراك/المميزات للحفظ التلقائي
    private static func isAutoSaveMediaAllowed() -> Bool {
        let jokerSettings = getJokerSettingsFromCache()
        guard jokerSettings.autoSaveSelfDestructingMedia else { return false }
        if jokerSettings.requireChannelSubscription && !JokerChannelSubscriptionManager.isSubscribed() {
            return false
        }
        return true
    }

    // MARK: - ميزة 2: وضع الشبح (Ghost Mode)
    // التحقق إذا كان وضع الشبح مفعّلاً
    public static func isGhostModeEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "joker_ghost_mode")
    }

    // التحقق إذا كان يجب إخفاء علامات القراءة
    public static func shouldHideReadReceipts() -> Bool {
        return isGhostModeEnabled()
    }

    // إشارة قراءة هذه الرسالة وكل ما قبلها (عند الضغط على أيقونة العين في الفقاعة)
    public static func markMessageAsRead(context: AccountContext, messageId: EngineMessage.Id) {
        let _ = JokerCoreHooks.readMessagesUpToViaNetwork(account: context.account, peerId: messageId.peerId, maxMessageId: messageId.id).start()
    }

    // MARK: - ميزة 3: الاحتفاظ بالرسائل المحذوفة
    public static func isKeepDeletedMessagesEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "joker_keep_deleted_messages")
    }

    // استدع هذه الدالة عند استلام حدث حذف رسالة من الخادم
    public static func onMessageDeletedRemotely(context: AccountContext, messageId: EngineMessage.Id) {
        let jokerSettings = getJokerSettingsFromCache()

        guard jokerSettings.keepDeletedMessages else { return }

        // التحقق من الاشتراك في القناة إذا كان مطلوباً
        if jokerSettings.requireChannelSubscription && !JokerChannelSubscriptionManager.isSubscribed() {
            return
        }

        // تسجيل المعرف محلياً ليظهر بجانبه علامة x في الفقاعة
        JokerCoreHooks.recordKeptDeletedMessages([messageId])
    }

    // استدع هذه الدالة عند حذف المحادثة بالكامل (Clear History)
    // ملاحظة: engine.messages.deleteHistory غير متوفر؛ الحذف الفعلي يحدث
    // من الكود الأصلي عند Clear History.
    public static func onClearHistory(context: AccountContext, peerId: EnginePeer.Id) {
        //禁止 الحذف الكامل إذا كان الاحتفاظ بالرسائل المحذوفة مفعلاً
        let jokerSettings = getJokerSettingsFromCache()
        if jokerSettings.keepDeletedMessages {
            print("Joker: Clear History مُعطل لأن الاحتفاظ بالرسائل المحذوفة مفعل: \(peerId)")
            return
        }
        print("Joker: تم حذف المحادثة بالكامل نهائياً: \(peerId)")
    }

    // MARK: - ميزة 4: الترجمة التلقائية للبريميوم
    public static func isForcePremiumTranslationEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "joker_force_premium_translation")
    }

    // MARK: - ميزة 5: إضافة 100 حساب
    public static func isAllow100AccountsEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "joker_allow_100_accounts")
    }

    public static func getMaxAccountsCount() -> Int {
        if isAllow100AccountsEnabled() {
            return 100
        }
        return 3 // الحد الافتراضي
    }

    // MARK: - ميزة 6: التحقق من الاشتراك في القناة
    public static func requireChannelSubscription() -> Bool {
        return UserDefaults.standard.bool(forKey: "joker_require_subscription")
    }

    // MARK: - helper
    // قراءة متزامنة للإعدادات من قيم UserDefaults المُرآة (تكتَبها
    // updateJokerSettingsInteractively) عبر واجهة JokerSettings العامة.
    private static func getJokerSettingsFromCache() -> JokerSettings {
        return JokerSettings.defaultSettings
            .withUpdatedAutoSaveSelfDestructingMedia(UserDefaults.standard.bool(forKey: "joker_auto_save_media"))
            .withUpdatedAllow100Accounts(UserDefaults.standard.bool(forKey: "joker_allow_100_accounts"))
            .withUpdatedGhostMode(UserDefaults.standard.bool(forKey: "joker_ghost_mode"))
            .withUpdatedForcePremiumTranslation(UserDefaults.standard.bool(forKey: "joker_force_premium_translation"))
            .withUpdatedKeepDeletedMessages(UserDefaults.standard.bool(forKey: "joker_keep_deleted_messages"))
            .withUpdatedRequireChannelSubscription(UserDefaults.standard.bool(forKey: "joker_require_subscription"))
            .withUpdatedFreezeLastSeen(UserDefaults.standard.bool(forKey: "joker_freeze_last_seen"))
            .withUpdatedBypassCopyProtection(UserDefaults.standard.bool(forKey: "joker_bypass_copy_protection"))
    }
}
