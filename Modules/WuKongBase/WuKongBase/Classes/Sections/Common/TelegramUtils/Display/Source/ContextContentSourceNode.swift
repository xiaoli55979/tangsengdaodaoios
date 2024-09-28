import Foundation
import AsyncDisplayKit

open class ContextReferenceContentNode: ASDisplayNode {
    override public init() {
        super.init()
    }
}

//@objc public class WKContextExtractedContentContainingNode:ASDisplayNode {
//    @objc  public var contentNode: ContextExtractedContentNode {
//        get {
//            return self.contextExtractedContentContainingNode.contentNode
//        }
//    }
//    @objc public var contentRect:CGRect {
//        get {
//            return self.contextExtractedContentContainingNode.contentRect
//        }
//        set(v) {
//            self.contextExtractedContentContainingNode.contentRect = v
//        }
//    }
//    private let contextExtractedContentContainingNode: ContextExtractedContentContainingNode
//    @objc public var willUpdateIsExtractedToContextPreview: ((Bool) -> Void)?
//    public override init() {
//
//        self.contextExtractedContentContainingNode = ContextExtractedContentContainingNode()
//        
//        super.init()
//        
//        
//    }
//}

@objc public final class ContextExtractedContentContainingNode: ASDisplayNode {
    @objc  public let contentNode: ContextExtractedContentNode
    @objc public var contentRect: CGRect = CGRect()
    public var isExtractedToContextPreview: Bool = false
    public var willUpdateIsExtractedToContextPreview: ((Bool, ContainedViewLayoutTransition) -> Void)?
    public var isExtractedToContextPreviewUpdated: ((Bool) -> Void)?
    public var updateAbsoluteRect: ((CGRect, CGSize) -> Void)?
    public var applyAbsoluteOffset: ((CGPoint, ContainedViewLayoutTransitionCurve, Double) -> Void)?
    public var applyAbsoluteOffsetSpring: ((CGFloat, Double, CGFloat) -> Void)?
    public var layoutUpdated: ((CGSize, ListViewItemUpdateAnimation) -> Void)?
    public var updateDistractionFreeMode: ((Bool) -> Void)?
    public var requestDismiss: (() -> Void)?
    
    public override init() {
        self.contentNode = ContextExtractedContentNode()
        
        super.init()
        
        self.addSubnode(self.contentNode)
    }
    
    @objc public func layoutUpdatedForOC(size:CGSize) {
        self.layoutUpdated?(size,.None)
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.contentNode.supernode === self {
            return self.contentNode.hitTest(self.view.convert(point, to: self.contentNode.view), with: event)
        } else {
            return nil
        }
    }
}

public final class ContextExtractedContentNode: ASDisplayNode {
    public var customHitTest: ((CGPoint) -> UIView?)?

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = self.view.hitTest(point, with: event)
        if result === self.view {
            return nil
        } else {
            return result
        }
    }
}

public final class ContextControllerContentNode: ASDisplayNode {
    public let sourceNode: ASDisplayNode
    public let controller: ViewController
    private let tapped: () -> Void
    
    public init(sourceNode: ASDisplayNode, controller: ViewController, tapped: @escaping () -> Void) {
        self.sourceNode = sourceNode
        self.controller = controller
        self.tapped = tapped
        
        super.init()
        
        self.addSubnode(controller.displayNode)
    }
    
    override public func didLoad() {
        super.didLoad()
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapGesture(_:))))
    }
    
    @objc private func tapGesture(_ recognizer: UITapGestureRecognizer) {
        if case .ended = recognizer.state {
            self.tapped()
        }
    }
    
    public func updateLayout(size: CGSize, transition: ContainedViewLayoutTransition) {
        transition.updateFrame(node: self.controller.displayNode, frame: CGRect(origin: CGPoint(), size: size))
    }
}

public enum ContextContentNode {
    case reference(view: UIView)
    case extracted(node: ContextExtractedContentContainingNode, keepInPlace: Bool)
    case controller(ContextControllerContentNode)
}
