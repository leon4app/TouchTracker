import UIKit

extension Array where Element: Equatable {
    
    // Remove first collection element that is equal to the given `object`:
    mutating func remove(_ object: Element) {
        if let index = index(of: object) {
            remove(at: index)
        }
    }
}

class DrawView : UIView, UIGestureRecognizerDelegate
{
    lazy var moveRecognizer: UIPanGestureRecognizer = {
        var moveRecognizer = UIPanGestureRecognizer(target: self, action: #selector(moveLine))
        return moveRecognizer
    }()
    var linesInProgress = Dictionary<NSValue,Line>()
    var finishedLines = Array<Line>()
    weak var selectedLine: Line?
    override var canBecomeFirstResponder: Bool { return true }
    
    override init(frame r: CGRect) {
        super.init(frame: r)
        
        
        backgroundColor = UIColor.gray
        isMultipleTouchEnabled = true
        //doubleTapRecognizer
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.doubleTap))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.delaysTouchesBegan = true
        addGestureRecognizer(doubleTapRecognizer)
        //tapRecognizer
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tap))
        tapRecognizer.delaysTouchesBegan = true
        tapRecognizer.require(toFail: doubleTapRecognizer)
        addGestureRecognizer(tapRecognizer)
        //longpressRecognizer
        let pressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress))
        addGestureRecognizer(pressRecognizer)
        
        moveRecognizer.delegate = self
        moveRecognizer.cancelsTouchesInView = false
        addGestureRecognizer(moveRecognizer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    

    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.moveRecognizer {
            return true
        }
        return false
    }
    
    //MARK: Draw functions
    
    func strokeLine(line: Line)
    {
        let bp = UIBezierPath()
        bp.lineWidth = 10
        bp.lineCapStyle = .round
        
        bp.move(to: line.begin!)
        bp.addLine(to: line.end!)
        bp.stroke()
    }
    
    override func draw(_ rect: CGRect) {
        UIColor.black.set()
        for line in self.finishedLines {
            self.strokeLine(line: line)
        }
        
        UIColor.red.set()
        for (_,value) in linesInProgress {
            strokeLine(line: value)
        }
        
        if self.selectedLine != nil {
            UIColor.green.set()
            self.strokeLine(line: self.selectedLine!)
        }
    }
    
    func lineAtPoint(p: CGPoint) -> Line? {
        for l in self.finishedLines {
            let start = l.begin!
            let end = l.end!
            
            for t in stride(from:0.0, to:1.0, by:0.5) {
                let x = start.x + CGFloat(t)  * (end.x - start.x)
                let y = start.y + CGFloat(t) * (end.y - start.y)
                
                if hypot(x - p.x, y - p.y) < 20.0
                {
                    return l
                }
            }
            
        }
        return nil
    }
    
    func deleteLine()
    {
        self.finishedLines.remove(selectedLine!)

        self.setNeedsDisplay()
    }
    
    func moveLine(_ gr: UIPanGestureRecognizer)  {
        print("Recognizer Pan")
        if (self.selectedLine == nil) {
            return
        }
        if gr.state == UIGestureRecognizerState.changed {
            let translation = gr.translation(in: self)
            
            var begin = self.selectedLine!.begin!
            var end = self.selectedLine!.end!
            begin.x = begin.x + translation.x
            begin.y = begin.y + translation.y
            end.x = end.x + translation.x
            end.y = end.y + translation.y
            
            self.selectedLine!.begin = begin
            self.selectedLine!.end = end
            
            self.setNeedsDisplay()
            
            gr.setTranslation(.zero, in: self)
        }
    }
    
    //MARK: Touches functions

     override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("\(NSStringFromSelector(#function))")
        for t: UITouch in touches {
            let location: CGPoint = t.location(in: self)
            let line = Line()
            line.begin = location
            line.end = location
            let key = NSValue(nonretainedObject: t)
            linesInProgress[key] = line
        }
        setNeedsDisplay()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("\(NSStringFromSelector(#function))")
        for t: UITouch in touches {
            let key = NSValue(nonretainedObject: t)
            let line: Line? = linesInProgress[key]
            line?.end = t.location(in: self)
        }
        setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("\(NSStringFromSelector(#function))")
        for t: UITouch in touches {
            let key = NSValue(nonretainedObject: t)
            let line: Line = linesInProgress[key]!
            finishedLines.append(line as Line)
            linesInProgress.removeValue(forKey: key)
        }
        setNeedsDisplay()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("\(NSStringFromSelector(#function))")
        for t: UITouch in touches {
            let key = NSValue(nonretainedObject: t)
            linesInProgress.removeValue(forKey: key)
        }
        setNeedsDisplay()
    }
    
    func doubleTap(_ gr: UIGestureRecognizer) {
        print("Recognizer Double Tap")
        linesInProgress.removeAll()
        finishedLines.removeAll()
        setNeedsDisplay()
    }
    
    func tap(_ gr: UITapGestureRecognizer) {
        print("Recognized Tap")
        let point: CGPoint = gr.location(in: self)
        selectedLine = lineAtPoint(p: point)
        if (selectedLine != nil) {
            becomeFirstResponder()
            let menu = UIMenuController.shared
            let deleteItem = UIMenuItem(title: "Delete", action: #selector(self.deleteLine))
            menu.menuItems = [deleteItem]
            menu.setTargetRect(CGRect(x: CGFloat(point.x), y: CGFloat(point.y), width: CGFloat(2), height: CGFloat(2)), in: self)
            menu.setMenuVisible(true, animated: true)
        }
        else {
            UIMenuController.shared.setMenuVisible(false, animated: true)
        }
        setNeedsDisplay()
    }
    
    func longPress(_ gr: UIGestureRecognizer) {
        print("Recognized Long Press")
        if gr.state == .began {
            let point: CGPoint = gr.location(in: self)
            selectedLine = lineAtPoint(p: point)
            if (selectedLine != nil) {
                linesInProgress.removeAll()
            }
        }
        else if gr.state == .ended {
            selectedLine = nil
        }
        
        setNeedsDisplay()
    }

}
