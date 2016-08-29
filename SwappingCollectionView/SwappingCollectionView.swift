
import UIKit

extension UIView {
    
    func snapshot() -> UIImage {
        UIGraphicsBeginImageContext(self.bounds.size)
        self.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension CGPoint {
    func distanceToPoint(p:CGPoint) -> CGFloat {
        return sqrt(pow((p.x - x), 2) + pow((p.y - y), 2))
    }
}

struct SwapDescription : Hashable {
    var firstItem : Int
    var secondItem : Int
    
    var hashValue: Int {
        get {
            return (firstItem * 10) + secondItem
        }
    }
}

func ==(lhs: SwapDescription, rhs: SwapDescription) -> Bool {
    return lhs.firstItem == rhs.firstItem && lhs.secondItem == rhs.secondItem
}

class SwappingCollectionView: UICollectionView {
    
    var interactiveIndexPath : NSIndexPath?
    var interactiveView : UIView?
    var interactiveCell : UICollectionViewCell?
    var swapSet : Set<SwapDescription> = Set()
    var previousPoint : CGPoint?
    
    static let distanceDelta:CGFloat = 2

    override func beginInteractiveMovementForItemAtIndexPath(indexPath: NSIndexPath) -> Bool {
        
        self.interactiveIndexPath = indexPath
        
        self.interactiveCell = self.cellForItemAtIndexPath(indexPath)
        
        self.interactiveView = UIImageView(image: self.interactiveCell?.snapshot())
        self.interactiveView?.frame = self.interactiveCell!.frame
        
        self.addSubview(self.interactiveView!)
        self.bringSubviewToFront(self.interactiveView!)
        
        self.interactiveCell?.hidden = true
        
        return true
    }
    
    override func updateInteractiveMovementTargetPosition(targetPosition: CGPoint) {
        
        if (self.shouldSwap(targetPosition)) {
        
            if let hoverIndexPath = self.indexPathForItemAtPoint(targetPosition), let interactiveIndexPath = self.interactiveIndexPath {
                
                let swapDescription = SwapDescription(firstItem: interactiveIndexPath.item, secondItem: hoverIndexPath.item)
                
                if (!self.swapSet.contains(swapDescription)) {
                
                    self.swapSet.insert(swapDescription)
                    
                    self.performBatchUpdates({
                        self.moveItemAtIndexPath(interactiveIndexPath, toIndexPath: hoverIndexPath)
                        self.moveItemAtIndexPath(hoverIndexPath, toIndexPath: interactiveIndexPath)
                        }, completion: {(finished) in
                            self.swapSet.remove(swapDescription)
                            self.interactiveIndexPath = hoverIndexPath
                    })
                }
            }
        }
        
        self.interactiveView?.center = targetPosition
        self.previousPoint = targetPosition
    }
    
    override func endInteractiveMovement() {
        self.cleanup()
    }
    
    override func cancelInteractiveMovement() {
        self.cleanup()
    }

    func cleanup() {
        self.interactiveCell?.hidden = false
        self.interactiveView?.removeFromSuperview()
        self.interactiveView = nil
        self.interactiveCell = nil
        self.interactiveIndexPath = nil
        self.previousPoint = nil
        self.swapSet.removeAll()
    }
    
    func shouldSwap(newPoint: CGPoint) -> Bool {
        if let previousPoint = self.previousPoint {
            let distance = previousPoint.distanceToPoint(newPoint)
            return distance < SwappingCollectionView.distanceDelta
        }
        
        return false
    }
}
