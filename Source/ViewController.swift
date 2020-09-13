import UIKit

var game = Game()

class ViewController: UIViewController {
    override var prefersStatusBarHidden : Bool { return true;  }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        quartzView = view
        screenSize = view.bounds.size

        game.reset()
    }
    
    @IBAction func newGamesPressed(_ sender: UIButton) {
        game.reset()
        view.setNeedsDisplay()
    }
}

