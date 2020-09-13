import UIKit

var pt = CGPoint() // mouse touch coord
var context:CGContext! = nil
var screenSize = CGSize()
var quartzView:UIView! = nil

class QuartzView: UIView
{
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    override func draw(_ rect: CGRect) {
        context = UIGraphicsGetCurrentContext()
        context.scaleBy(x: screenSize.width / SCREEN_XS, y: screenSize.height / SCREEN_YS)
 
        game.draw()
    }
    
    @IBAction func NewGameButton(_ sender: AnyObject) {
        game.reset()
        setNeedsDisplay()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            game.touched(touch.location(in: self))
            setNeedsDisplay()
        }
    }
}

func drawText(_ x:CGFloat, _ y:CGFloat, _ txt:String, _ fontSize:Int, _ color:UIColor, _ justifyCode:Int) {  // 0,1,2 = left,center,right
    UIGraphicsPushContext(context)
    
    let a1 = NSMutableAttributedString(
        string: txt,
        attributes: [
            kCTFontAttributeName as NSAttributedString.Key:UIFont(name: "Helvetica", size: CGFloat(fontSize))!,
            NSAttributedStringKey.foregroundColor : color
    ])
    
    var cx = CGFloat(x)
    let size = a1.size()

    switch justifyCode {
    case 1 : cx -= size.width/2
    case 2 : cx -= size.width
    default : break
    }
    
    a1.draw(at: CGPoint(x:cx, y:CGFloat(y)))
    UIGraphicsPopContext()
}

func drawRectangle(_ x:CGFloat, _ y:CGFloat, _ xs:CGFloat, _ ys:CGFloat) { context.stroke(CGRect(x:x,y:y,width:xs,height:ys)) }
func drawFilledRectangle(_ x:CGFloat, _ y:CGFloat, _ xs:CGFloat, _ ys:CGFloat)  { context.fill(CGRect(x:x,y:y,width:xs,height:ys)) }

