import Foundation
import UIKit
import AsyncDisplayKit
import Display
import TelegramCore
import SwiftSignalKit

// MARK: - Joker Mod Bubble Views
// عناصر الواجهة المضافة بواسطة تعديلات Talogram (الجوكر)

// زر العين لوضع الشبح: يوضع فوق الرسائل الواردة غير المقروءة، وعند الضغط عليه
// تُسلَّم إشعارات القراءة حتى هذه الرسالة فقط (عبر messages.readHistory بـ maxId).
// أيقونة العين تظهر فقط عندما يكون وضع الشبح مفعّلاً وتكون الرسالة غير مقروءة.
public class JokerGhostModeEyeButton: ASDisplayNode {
    private var messageId: EngineMessage.Id
    private let onEyeTapped: (EngineMessage.Id) -> Void

    private let iconNode: ASImageNode

    public init(messageId: EngineMessage.Id, onEyeTapped: @escaping (EngineMessage.Id) -> Void) {
        self.messageId = messageId
        self.onEyeTapped = onEyeTapped

        self.iconNode = ASImageNode()
        self.iconNode.contentMode = .scaleAspectFit
        self.iconNode.displaysAsynchronously = false
        self.iconNode.isLayerBacked = true

        super.init()
        self.isOpaque = false
        self.alpha = 0.0

        self.addSubnode(self.iconNode)
        if let image = UIImage(systemName: "eye.circle.fill")?.withRenderingMode(.alwaysTemplate) {
            self.iconNode.image = image
        }
        self.iconNode.tintColor = UIColor(white: 1.0, alpha: 0.92)
    }

    public func set(messageId: EngineMessage.Id) {
        self.messageId = messageId
    }

    override public func didLoad() {
        super.didLoad()
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap))
        self.view.addGestureRecognizer(tap)
    }

    override public func layout() {
        super.layout()
        self.iconNode.frame = self.bounds
    }

    @objc private func handleTap() {
        self.onEyeTapped(self.messageId)
    }

    // تحديث زر العين حسب حالة الظهور (يُستدعى من تخطيط الفقاعة)
    public func setEyeVisible(_ visible: Bool, frame: CGRect) {
        self.alpha = visible ? 1.0 : 0.0
        self.frame = frame
        self.isUserInteractionEnabled = visible
        if visible, self.bounds.size != frame.size {
            self.iconNode.frame = self.bounds
        }
    }
}

// علامة x الصغيرة التي تظهر بجانب الرسائل التي حذفها الطرف الآخر
// (عند تفعيل ميزة الاحتفاظ بالرسائل المحذوفة)
public class JokerDeletedMessageMark: ASDisplayNode {
    private let iconNode: ASImageNode

    public override init() {
        self.iconNode = ASImageNode()
        self.iconNode.contentMode = .scaleAspectFit
        self.iconNode.displaysAsynchronously = false
        self.iconNode.isLayerBacked = true

        super.init()
        self.isOpaque = false
        self.alpha = 0.0

        self.addSubnode(self.iconNode)
        if let image = UIImage(systemName: "xmark.circle.fill")?.withRenderingMode(.alwaysTemplate) {
            self.iconNode.image = image
        }
        self.iconNode.tintColor = UIColor(red: 0.86, green: 0.18, blue: 0.18, alpha: 0.95)
    }

    override public func didLoad() {
        super.didLoad()
    }

    override public func layout() {
        super.layout()
        self.iconNode.frame = self.bounds
    }

    // تحديث ظهور علامة الحذف (يُستدعى من تخطيط الفقاعة)
    public func setDeletedMarkVisible(_ visible: Bool, frame: CGRect) {
        self.alpha = visible ? 1.0 : 0.0
        self.frame = frame
        if visible, self.bounds.size != frame.size {
            self.iconNode.frame = self.bounds
        }
    }
}
