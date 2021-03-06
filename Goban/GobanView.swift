//
//  GobanView.swift
//  GobanSampleProject
//
//  Created by Bobo on 3/19/16.
//  Copyright © 2016 Boris Emorine. All rights reserved.
//

import UIKit

func ==(lhs: GobanPoint, rhs: GobanPoint) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

struct GobanPoint: Hashable {
    var x: Int = 0
    var y: Int = 0
    
    var hashValue: Int {
        get {
            return "\(self.x), \(self.y)".hashValue
        }
    }
    
    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
    
    init?(SGFString: String) {
        guard SGFString.characters.count == 2 else {
            return nil
        }
        
        let alphabet = "abcdefghijklmnopqrstuvwxyz"
        if let indexForCharacterInString = alphabet.characters.indexOf(SGFString.characters.first!) {
            x = alphabet.startIndex.distanceTo(indexForCharacterInString) + 1
        } else {
            return nil
        }
        
        if let indexForCharacterInString = alphabet.characters.indexOf(SGFString.characters.last!) {
            y = alphabet.startIndex.distanceTo(indexForCharacterInString) + 1
        } else {
            return nil
        }
    }
}

struct GobanSize {
    var width: Int = 0
    var height: Int = 0
}

protocol GobanTouchProtocol: class {
    func didTouchGobanWithClosestGobanPoint(goban: GobanView, atGobanPoint gobanPoint: GobanPoint)
    func didEndTouchGobanWithClosestGobanPoint(goban: GobanView, atGobanPoint gobanPoint: GobanPoint?)
}

/** The delegate of a `GobanView` must adopt the `GobanTouchProtocol`.
The protocol allows the delegate to get information about when a stone gets set.
 */
protocol GobanProtocol: class {
    func didSetStoneAtGobanPoint(gobanView: GobanView, gobanPoint: GobanPoint)
}

/** `GobanView` is used to create highly custmizable Goban representations.
 */
class GobanView: UIView {
    
    // MARK: Variables
    
    /** The actual size of the goban. That is, the number of lines that composes each side of the board.
    Setting this variable to a new value will redraw the `GobanView`.
    If `gobanSize` is set to a common size (9x9, 13x13 or 19x19), the star points will be automatically calculated. Defaults to 19x19.
    - SeeAlso: `startPoints`
    */
    var gobanSize: GobanSize = GobanSize(width: 19, height: 19) {
        didSet {
            if gobanSize.width == 9 && gobanSize.height == 9 {
                self.starPoints = [GobanPoint(x: 3, y: 3), GobanPoint(x: 7, y: 3), GobanPoint(x: 5, y: 5), GobanPoint(x: 3, y: 7), GobanPoint(x: 7, y: 7)]
            } else if gobanSize.width == 13 && gobanSize.height == 13 {
                self.starPoints = [GobanPoint(x: 4, y: 4), GobanPoint(x: 10, y: 4), GobanPoint(x: 7, y: 7), GobanPoint(x: 4, y: 10), GobanPoint(x: 10, y: 10)]
            } else if gobanSize.width == 19 && gobanSize.height == 19 {
                self.starPoints = [GobanPoint(x: 4, y: 4), GobanPoint(x: 10, y: 4), GobanPoint(x: 16, y: 4), GobanPoint(x: 4, y: 10), GobanPoint(x: 10, y: 10), GobanPoint(x: 16, y: 10), GobanPoint(x: 4, y: 16), GobanPoint(x: 10, y: 16), GobanPoint(x: 16, y: 16)]
            }
            drawGoban()
        }
    }
    
    /** An array of positions for the star points on the Goban to be drawn. Defautls to an empty array.
     - SeeAlso: `gobanSize`
     */
    var starPoints = [GobanPoint]() {
        didSet {
            drawStarPoints()
        }
    }
    
    /** The color of the lines (grid) on the goban. Defaults to R:0.35, G: 0.35, B: 0.35, A: 1.0.
     */
    let lineColor = UIColor(red: 90.0 / 255.0, green: 90.0 / 255.0, blue: 90.0 / 255.0, alpha: 1.0)
    
    /** The width of the lines (grid) on the goban. Defaults to 2.0.
     */
    let lineWidth: CGFloat = 2.0
    
    /** The background color of the goban. Defaults to R:0.96, G: 0.82, B: 0.63, A: 1.0.
     */
    let gobanBackgroundColor = UIColor(red: 240.0 / 255.0, green: 211.0 / 255.0, blue: 159.0 / 255.0, alpha: 1.0)
    
    /** The color of the white stones. Defaults to white.
     */
    let whiteStoneColor = UIColor.whiteColor()
    
    /** The color of the black stones. Defaults to black.
     */
    let blackStoneColor = UIColor.blackColor()
    
    /** The empty space between the grid and the actual goban limits as a percentage of the goban size. Defaults to 0.07.
     */
    var padding: CGFloat = 0.07 {
        didSet {
            if padding > 1.0 {
                padding = 1.0
            } else if padding < 0.0 {
                padding = 0.0
            }
            
            drawGoban()
        }
    }
    
    /** The frame of the grid on the goban.
     */
    private var gridFrame: CGRect {
        get {
            return CGRectMake(frame.size.width * padding, frame.size.height * padding, frame.size.width - 2 * padding * frame.size.width, frame.size.height - 2 * padding * frame.size.height)
        }
        set { }
    }

    /** Gesture recognizer used to track user inputs on the goban.
    - SeeAlso: `gobanTouchDelegate`
     */
    private var longPressGestureRecognizer: UILongPressGestureRecognizer?
    
    /** The object that acts as the delegate for touch inputs on `GobanView`.
    - SeeAlso: `GobanTouchProtocol`
     */
    weak var gobanTouchDelegate: GobanTouchProtocol? {
        didSet {
            if longPressGestureRecognizer == nil {
                let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(GobanView.didLongPressGoban(_:)))
                longPressGestureRecognizer.minimumPressDuration = 0.0
                self.addGestureRecognizer(longPressGestureRecognizer)
            }
        }
    }
    
    /** The object that acts as the delegate of `GobanView`.
    - SeeAlso: `GobanProtocol`
     */
    weak var delegate: GobanProtocol?
    
    // MARK: Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    convenience init(size: GobanSize, frame: CGRect) {
        self.init(frame: frame)
        self.gobanSize = size
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = gobanBackgroundColor
        layer.masksToBounds = true
    }
    
    // MARK: Drawings
    
    private var gridLayer = CAShapeLayer()
    private var starPointsLayer = CAShapeLayer()
    
    override func drawRect(rect: CGRect) {
        drawGoban()
    }
    
    private func drawGoban() {
        removeSubLayers()

        drawGrid()
        drawStarPoints()
        if padding > 0.0 {
            drawBorder()
        }
    }
    
    private func drawGrid() {
        gridLayer.removeFromSuperlayer()
        gridLayer = layerForGridWithFrame(self.bounds, withGobanSize: gobanSize, padding: padding)
        layer.addSublayer(gridLayer)
    }
    
    private func drawStarPoints() {
        starPointsLayer.removeFromSuperlayer()
        starPointsLayer = layerForStartPointsWithFrame(self.bounds, withGobanSize: gobanSize, padding: padding, starPoints: starPoints)
        layer.addSublayer(starPointsLayer)
    }
    
    private func drawBorder() {
        layer.borderWidth = lineWidth
        layer.borderColor = lineColor.CGColor
    }
    
    private func drawStone(stone: StoneProtocol, atGobanPoint gobanPoint: GobanPoint) -> StoneModel {
        let stoneSize = sizeForStoneWithGobanSize(gobanSize, inFrame: gridFrame)
        let stoneCenter = centerForStoneAtGobanPoint(gobanPoint, gobanSize: gobanSize, inFrame: gridFrame)
        let stoneFrame = CGRectMake(stoneCenter.x - stoneSize / 2.0, stoneCenter.y - stoneSize / 2.0, stoneSize, stoneSize)
        
        let stoneLayer = layerForStoneWithFrame(stoneFrame, color: colorForStone(stone))
        
        let stoneModel = StoneModel(stoneColor: stone.stoneColor, disabled: stone.disabled, layer: stoneLayer, gobanPoint: gobanPoint)
        
        layer.addSublayer(stoneLayer)
        
        return stoneModel
    }
    
    func reload() {
        drawGoban()
    }
    
    // MARK: Layers
    
    private func layerForGridWithFrame(frame: CGRect, withGobanSize size: GobanSize, padding: CGFloat) -> CAShapeLayer {
        let gridLayer = CAShapeLayer()
        gridLayer.frame = frame
        gridLayer.path = pathForGridInRect(gridFrame, withGobanSize: size).CGPath
        gridLayer.fillColor = UIColor.clearColor().CGColor
        gridLayer.strokeColor = lineColor.CGColor
        gridLayer.lineWidth = lineWidth
        
        return gridLayer
    }
    
    private func layerForStartPointsWithFrame(frame: CGRect, withGobanSize size: GobanSize, padding: CGFloat, starPoints: [GobanPoint]) -> CAShapeLayer {
        let starPointsLayer = CAShapeLayer()
        starPointsLayer.frame = frame
        starPointsLayer.path = pathForStarPointsInRect(gridFrame, withGobanSize: gobanSize, starPoints: starPoints).CGPath
        starPointsLayer.fillColor = lineColor.CGColor
        
        return starPointsLayer
    }
    
    private func layerForStoneWithFrame(frame: CGRect, color: UIColor) -> CAShapeLayer {
        let stoneLayer = CAShapeLayer()
        stoneLayer.frame = frame
        stoneLayer.path = pathForStoneInRect(stoneLayer.bounds).CGPath
        stoneLayer.fillColor = color.CGColor
        stoneLayer.strokeColor = UIColor.clearColor().CGColor
        
        return stoneLayer
    }
    
    // MARK: Paths
    
    private func pathForGridInRect(rect: CGRect, withGobanSize gobanSize: GobanSize) -> UIBezierPath {
        let gridPath = UIBezierPath()
        
        let heightLineInterval = rect.size.height / CGFloat(gobanSize.height - 1)
        let widthLineInterval = rect.size.width / CGFloat(gobanSize.width - 1)

        for i in 0 ..< Int(gobanSize.height) {
            gridPath.moveToPoint(CGPointMake(rect.origin.x, CGFloat(i) * heightLineInterval + rect.origin.y))
            gridPath.addLineToPoint(CGPointMake(rect.size.width + rect.origin.x, CGFloat(i) * heightLineInterval + rect.origin.y))
        }

        for i in 0 ..< Int(gobanSize.width) {
            gridPath.moveToPoint(CGPointMake(CGFloat(i) * widthLineInterval + rect.origin.x, rect.origin.y))
            gridPath.addLineToPoint(CGPointMake(CGFloat(i) * widthLineInterval + rect.origin.x, rect.size.height + rect.origin.y))
        }
        
        return gridPath
    }
    
    private func pathForStarPointsInRect(rect: CGRect, withGobanSize gobanSize: GobanSize, starPoints: [GobanPoint]) -> UIBezierPath {
        let starPointsPath = UIBezierPath()
        let starSize = sizeForStarPointWithGobanSize(gobanSize, inFrame: rect)
        for gobanPoint in starPoints {
            let point = centerForStoneAtGobanPoint(gobanPoint, gobanSize: gobanSize, inFrame: rect)
            starPointsPath.appendPath(UIBezierPath(ovalInRect: CGRectMake(point.x - starSize / 2.0, point.y - starSize / 2.0, starSize, starSize)))
        }
        
        return starPointsPath
    }
    
    private func pathForStoneInRect(rect: CGRect) -> UIBezierPath {
        let stonePath = UIBezierPath(ovalInRect: rect)
        
        return stonePath
    }
    
    // MARK: Stones
    
    func setStone(stone: StoneProtocol, atGobanPoint gobanPoint: GobanPoint) -> StoneModel? {
        guard gobanPoint.x >= 1 && gobanPoint.x <= gobanSize.width
            && gobanPoint.y >= 1 && gobanPoint.y <= gobanSize.height
            else {
                print("setStoneAtPoint -- Point outside of Goban")
                return nil
        }
        
        let stoneModel = drawStone(stone, atGobanPoint: gobanPoint)
        delegate?.didSetStoneAtGobanPoint(self, gobanPoint: gobanPoint)
        
        return stoneModel
    }
    
    // MARK: Gesture Recognizers
    
    var longPressGestureRecognizerDidChange = false
    
    func didLongPressGoban(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        if self.gobanTouchDelegate != nil {
            switch longPressGestureRecognizer.state {
            case .Began:
                longPressGestureRecognizerDidChange = false
                break
            case .Changed:
                longPressGestureRecognizerDidChange = true
                var tapLocation = longPressGestureRecognizer.locationInView(longPressGestureRecognizer.view)
                tapLocation = CGPointMake(tapLocation.x, tapLocation.y - 30.0)
                if let closestGobanPoint = closestGobanPointFromPoint(tapLocation) {
                    gobanTouchDelegate?.didTouchGobanWithClosestGobanPoint(self, atGobanPoint: closestGobanPoint)
                }
                break
            case .Ended:
                var tapLocation = longPressGestureRecognizer.locationInView(longPressGestureRecognizer.view)
                if longPressGestureRecognizerDidChange == true {
                    tapLocation = CGPointMake(tapLocation.x, tapLocation.y - 30.0)
                }
                let closestGobanPoint = closestGobanPointFromPoint(tapLocation)
                gobanTouchDelegate?.didEndTouchGobanWithClosestGobanPoint(self, atGobanPoint: closestGobanPoint)
                
                break
            default:
                break
            }
        }
    }
    
    // MARK: Helper Methods
    
    private func removeSubLayers() {
        guard layer.sublayers != nil
            else {
                return
        }
        
        for subLayer in layer.sublayers! {
            subLayer.removeFromSuperlayer()
        }
    }
    
    func closestGobanPointFromPoint(point: CGPoint) -> GobanPoint? {
        guard CGRectContainsPoint(bounds, point) else {
            return nil
        }
        
        var closestGobanX =  CGFloat(gobanSize.width - 1) / (gridFrame.size.width / (point.x - gridFrame.origin.x)) + 1
        closestGobanX = min(max(closestGobanX, 1), CGFloat(gobanSize.width))
        
        var closestGobanY = CGFloat(gobanSize.height - 1) / (gridFrame.size.height / (point.y - gridFrame.origin.y)) + 1
        closestGobanY = min(max(closestGobanY, 1), CGFloat(gobanSize.height))
        
        return GobanPoint(x: Int(round(closestGobanX)), y: Int(round(closestGobanY)))
    }
    
    private func colorForStone(stone: StoneProtocol) -> UIColor {
        let alpha: CGFloat = stone.disabled == true ? 0.7 : 1.0
        let color = stone.stoneColor == GobanStoneColor.White ? whiteStoneColor : blackStoneColor
        
        return color.colorWithAlphaComponent(alpha)
    }
    
    // MARK: Calculations
    
    private func sizeForStoneWithGobanSize(gobanSize: GobanSize, inFrame frame: CGRect) -> CGFloat {
        let smallestGobanFrameSize = max(frame.size.width, frame.size.height)
        let smallestGobanSize = max(gobanSize.width, gobanSize.height)
        
        let stoneSize = smallestGobanFrameSize / CGFloat(smallestGobanSize)
        
        return stoneSize
    }
    
    private func sizeForStarPointWithGobanSize(gobanSize: GobanSize, inFrame frame: CGRect) -> CGFloat {
        return sizeForStoneWithGobanSize(gobanSize, inFrame: frame) / 2.0
    }
    
    private func centerForStoneAtGobanPoint(gobanPoint: GobanPoint, gobanSize: GobanSize, inFrame frame: CGRect) -> CGPoint {
        let heightLineInterval = frame.size.height / CGFloat(gobanSize.height - 1)
        let widthLineInterval = frame.size.width / CGFloat(gobanSize.width - 1)

        let y = heightLineInterval * CGFloat((gobanPoint.y - 1)) + frame.origin.x
        let x = widthLineInterval * CGFloat((gobanPoint.x - 1)) + frame.origin.y
        
        return CGPointMake(x, y)
    }
}
