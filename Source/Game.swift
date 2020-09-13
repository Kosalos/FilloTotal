import UIKit

let XMAX = 10
let YMAX = 12
let SCREEN_XS:CGFloat = 768
let SCREEN_YS:CGFloat = 1024
let NONE = -1

struct CellData {
    var number = Int()      // true number
    var user = Int()        // what user has assigned
    var count = Int()       // #cells in our group
    var display = Bool()    // display as a 'given' number?
    var correct = Bool()    // user group hass correct #members?
    var island = Bool()     // island cell shows total of neighbors
}

class Game {
    var cell = Array(repeating: Array(repeating:CellData(), count:YMAX), count:XMAX)
    var visited = Array(repeating: Array(repeating:Bool(), count:YMAX), count:XMAX)
    var gVisit = Array(repeating: Array(repeating:Bool(), count:YMAX), count:XMAX)
    var visitCount = Int()
    var matchNumber = Int()
    var numberCurrent = Int()
    var userNumber = Int()
    var cheatDisplay = false
    let shadowColor = UIColor.init(red:0, green:0, blue:0, alpha:1)
    let backgroundColor = UIColor.init(red:0.1126*0.8, green:0.4542*0.8, blue:0.3221*0.8, alpha:1)
    
    func resetVisited() {
        visitCount = 0
        for x in 0 ..< XMAX { for y in 0 ..< YMAX { visited[x][y] = false }}
    }
    
    func resetGVisit() { for x in 0 ..< XMAX { for y in 0 ..< YMAX { gVisit[x][y] = false }}}
    
    func isOdd(_ value:Int) -> Bool { return value & 1 != 0 }
    
    func legalCellIndex(_ x:Int, _ y:Int) -> Bool {
        if x == XMAX-1 && isOdd(y) { return false }
        return x >= 0 && x < XMAX && y >= 0 && y < YMAX
    }
    
    //MARK: - CountGroup
    
    // return true number of specified cell (unless == island)
    func neighborNumber(_ x:Int, _ y:Int) -> Int {
        if !legalCellIndex(x,y) || cell[x][y].island { return 0 }
        
        return cell[x][y].number
    }
    
    // return user number of specified cell (unless it is an island, or unassigned)
    func userNumber(_ x:Int, _ y:Int) -> Int {
        if !legalCellIndex(x,y) { return 0 }
        if cell[x][y].island { return 0 }
        
        if cell[x][y].display { return cell[x][y].number }
        if cell[x][y].user == NONE { return 0 }
        
        return cell[x][y].user
    }
    
    let offsetOdd:[(x:Int, y:Int)] = [ (0,-1),(1,-1),(-1,0),(1,0),(0,1),(1,1)]  // offsets of neighboring cells
    let offsetEven:[(x:Int, y:Int)] = [ (-1,-1),(0,-1),(-1,0),(1,0),(-1,1),(0,1)]
    
    // add specified cell to 'visited' array if cell number equals 'matchNumber'
    // if it does match, then also scan all his neighbors as well
    func addToGroup(_ x:Int, _ y:Int) {
        if !legalCellIndex(x,y) { return }
        if visited[x][y] { return }                     // already part of a previous group
        if cell[x][y].number != matchNumber { return }  // not part of current group
        if cell[x][y].island { return }                 // not part of any group
        
        visitCount += 1
        visited[x][y] = true
        
        if isOdd(y) {
            for v in offsetOdd {
                addToGroup(x + v.x, y + v.y)
            }
        }
        else {
            for v in offsetEven {
                addToGroup(x + v.x, y + v.y)
            }
        }
    }
    
    // used during reset().  visited[] = neighboring cells that form a group
    func countGroup(_ x:Int, _ y:Int) {
        resetVisited()        
        matchNumber = cell[x][y].number
        addToGroup(x,y)
    }
    
    //MARK: - reset
    
    func flipCoin() -> Bool { return Int.random(in: 0...1) == 1 }
    
    // used during reset(). set random block of cells to 'numberCurrent'
    func randomBlock(_ x:Int, _ y:Int) {
        var x = x
        var y = y
        if x < 0 { x = 0 } else if x >= XMAX { x = XMAX-1 }
        if y < 0 { y = 0 } else if y >= YMAX { y = YMAX-1 }
        
        if cell[x][y].island { return }
        
        cell[x][y].number = numberCurrent
        
        if (arc4random() & 15) < 2 { return }
        
        if flipCoin() {
            x += flipCoin() ? -1 : 1
        }
        else {
            y += flipCoin() ? -1 : 1
        }
        
        randomBlock(x,y)
    }
    
    func reset() {
        userNumber = NONE
        cheatDisplay = false
        
        // all cells same number
        numberCurrent = 1
        
        for x in 0 ..< XMAX {
            for y in 0 ..< YMAX {
                cell[x][y].island = false
                cell[x][y].number = numberCurrent
                cell[x][y].user = NONE
                cell[x][y].display = false
                cell[x][y].correct = false
            }
        }
        
        // assign island positions
        for i in 0 ..< 5 {
            let x = 1 + Int.random(in: 0 ... XMAX-2)
            let y = 1 + Int.random(in: 0 ... YMAX-2)
            cell[x][y].island = true
        }
        
        // random blocks stomped onto board
        for i in 0 ..< 30 {
            let x = Int.random(in: 0 ... XMAX-1)
            let y = Int.random(in: 0 ... YMAX-1)
            
            numberCurrent += 1
            randomBlock(x,y)
        }
        
        func splitLargeGroupIntoPieces(_ x:Int, _ y:Int) {
            while true {
                countGroup(x,y)
                if visitCount <= 12 { return }
                
                // group too large. split in 2
                var count:Int = 0
                
                for m in 0 ..< XMAX {
                    for n in 0 ..< YMAX {
                        if visited[m][n] {
                            count += 1
                            if count >= visitCount/3 {
                                cell[m][n].number += 100
                            }
                        }
                    }
                }
            }
        }
        
        // assign number according to group membership
        while true {
            var changeMade = false
            
            // track whether visited & assigned
            resetGVisit()
            
            for x in 0 ..< XMAX {
                for y in 0 ..< YMAX {
                    if gVisit[x][y] { continue } // already part of previously scanned group
                    
                    splitLargeGroupIntoPieces(x,y)
                    
                    // set cell # to number of cells in this group
                    for m in 0 ..< XMAX {
                        for n in 0 ..< YMAX {
                            if visited[m][n]  {
                                gVisit[m][n] = true
                                if cell[m][n].number != visitCount {
                                    changeMade = true
                                    cell[m][n].number = visitCount
                                }
                            }
                        }
                    }
                }
            }
            
            if !changeMade { break } // all same sized neighboring groups have been merged
        }
        
        // set at least one cell of each group as a 'given'
        resetGVisit()
        
        for x in 0 ..< XMAX {
            for y in 0 ..< YMAX {
                if gVisit[x][y] { continue } // already part of previously scanned group
                
                countGroup(x,y)
                
                var count:Int = 0
                for m in 0 ..< XMAX {
                    for n in 0 ..< YMAX {
                        if visited[m][n] {
                            gVisit[m][n] = true
                            
                            count += 1
                            if (visitCount == 1) || (count == visitCount/2) || (Int.random(in: 0 ... 15) < 1) {
                                cell[m][n].display = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    // for all island cells: determine 'true number' total and 'user group' total
    func updateIslandTotals() {
        for x in 0 ..< XMAX {
            for y in 0 ..< YMAX {
                if !cell[x][y].island { continue }
                cell[x][y].number = 0
                cell[x][y].user = 0
                
                if isOdd(y) {
                    for v in offsetOdd {
                        cell[x][y].number += neighborNumber(x + v.x, y + v.y)
                        cell[x][y].user += userNumber(x + v.x, y + v.y)
                    }
                }
                else {
                    for v in offsetEven {
                        cell[x][y].number += neighborNumber(x + v.x, y + v.y)
                        cell[x][y].user += userNumber(x + v.x, y + v.y)
                    }
                }
            }
        }
    }
    
    //MARK: - updateStatus
    
    func cellUserNumber(_ x:Int, _ y:Int) -> Int {
        if cell[x][y].display { return cell[x][y].number }
        return cell[x][y].user
    }
    
    func addToCheckUserCount(_ x:Int, _ y:Int) {
        if !legalCellIndex(x,y) { return }
        if visited[x][y] { return }
        if cellUserNumber(x,y) != matchNumber { return }
        
        visitCount += 1
        visited[x][y] = true
        
        if isOdd(y) {
            for v in offsetOdd {
                addToCheckUserCount(x + v.x, y + v.y)
            }
        }
        else {
            for v in offsetEven {
                addToCheckUserCount(x + v.x, y + v.y)
            }
        }
    }
    
    func checkUserCount(_ x:Int, _ y:Int) {
        resetVisited()
        
        matchNumber = cellUserNumber(x,y)
        addToCheckUserCount(x,y)
    }
    
    func updateStatus() {
        // assume all incorrect
        for x in 0 ..< XMAX {
            for y in 0 ..< YMAX {
                cell[x][y].correct = false
            }
        }
        
        // track whether visited
        resetGVisit()
        
        for x in 0 ..< XMAX {
            for y in 0 ..< YMAX {
                if gVisit[x][y] { continue } // already part of previously scanned group
                
                checkUserCount(x,y)
                
                var displayCell = false // each group must have at least one 'display' cell
                
                for m in 0 ..< XMAX {
                    for n in 0 ..< YMAX {
                        if visited[m][n] {
                            if cell[m][n].display { displayCell = true }
                            cell[m][n].count = visitCount
                        }
                        
                        if displayCell && (visitCount == cellUserNumber(x,y)) {
                            for m in 0 ..< XMAX {
                                for n in 0 ..< YMAX {
                                    if visited[m][n] {
                                        gVisit[m][n] = true
                                        cell[m][n].correct = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    //MARK: - draw
    
    let CellSize:CGFloat = 40
    var cellRadiusX:CGFloat = 20 * CGFloat(sqrtf(3))
    var cellRadiusY:CGFloat = 20
    
    let ULcornerX:CGFloat = 80
    let ULcornerY:CGFloat = 50
    let TextOffsetX:CGFloat = 0
    let TextOffsetY:CGFloat = -25
    let CellHopX:CGFloat = 0.05 + 22.0/12
    let CellHopY:CGFloat = 0.05 + 13.0/8
    
    var cellX = Int()
    var cellY = Int()
    
    let instructions:[String] = [
        "Each numbered cell is part of a group.",
        "That number is the number of cells in that group.",
        " ",
        "Click on a numbered cell, then neighboring cells to set them to the same number.",
        " ",
        "Also, the cells surrounding each island must total that number.",
    ]
    
    func draw() {
        func drawCell(_ x:Int, _ y:Int) {
            if x == XMAX-1 && isOdd(y) { return }
            
            // cell background
            if cell[x][y].island  {
                if cell[x][y].user != cell[x][y].number {
                    UIColor.red.set()
                }
                else {
                    UIColor.white.set()
                }
            }
            else {
                if cell[x][y].correct {
                    let v = cell[x][y].count
                    var r:CGFloat = (v & 4) != 0 ? 0.7 : 0.3
                    var g:CGFloat = (v & 2) != 0 ? 0.7 : 0.3
                    var b:CGFloat = (v & 1) != 0 ? 0.7 : 0.3
                    if v > 7  { r -= 0.1; g -= 0.1; b -= 0.1; }
                    
                    UIColor.init(red:r, green:g, blue:b, alpha:1).set()
                }
                else {
                    UIColor.gray.set()
                }
            }
            
            let cp = cellPosition(x,y)
            
            context.move(   to: CGPoint(x:cp.x,             y:cp.y-CellSize))
            context.addLine(to: CGPoint(x:cp.x+cellRadiusX, y:cp.y-cellRadiusY))
            context.addLine(to: CGPoint(x:cp.x+cellRadiusX, y:cp.y+cellRadiusY))
            context.addLine(to: CGPoint(x:cp.x,             y:cp.y+CellSize))
            context.addLine(to: CGPoint(x:cp.x-cellRadiusX, y:cp.y+cellRadiusY))
            context.addLine(to: CGPoint(x:cp.x-cellRadiusX, y:cp.y-cellRadiusY))
            context.addLine(to: CGPoint(x:cp.x,             y:cp.y-CellSize))
            context.drawPath(using: .fillStroke)
            
            let str = String(cell[x][y].number)
            
            if cell[x][y].island  {
                drawText(cp.x+TextOffsetX, cp.y+TextOffsetY, str, 36, .black, 1)
                
                let v = cell[x][y].user - cell[x][y].number
                if v != 0 {
                    drawText(cp.x+11, cp.y+9, String(v), 16, .black, 1)
                }
                
                return
            }
            
            if cheatDisplay && (cell[x][y].user != cell[x][y].number) && !cell[x][y].display {
                drawText(cp.x+TextOffsetX, cp.y+TextOffsetY+36,str, 26, .cyan, 1)
            }
            
            // 'given' display
            if cell[x][y].display  {
                drawText(cp.x+TextOffsetX, cp.y+TextOffsetY, str, 36, .yellow, 1)
            }
            else {  // user number
                let un = cell[x][y].user
                if un != NONE  {
                    drawText(cp.x+TextOffsetX, cp.y+TextOffsetY, String(un), 36, .white, 1)
                }
            }
            
            // group count (if incorrect)
            if(!cell[x][y].correct && cell[x][y].user != NONE) {
                drawText(cp.x+12, cp.y+10, String(cell[x][y].count), 14, .white, 1)
            }
        }
        backgroundColor.set()
        drawFilledRectangle(0,0,SCREEN_XS,SCREEN_YS)
        
        context.setShadow(offset:CGSize(width:2,height:2), blur:1, color:shadowColor.cgColor)
        
        let x:CGFloat = 20
        var y:CGFloat = 840
        
        drawText(x,y,"FilloTotal",24,.white,0)
        y += 32
        for s in instructions {
            drawText(x,y,s,18,.white,0)
            y += 20
        }
        
        updateIslandTotals()
        updateStatus()
        
        for x in 0 ..< XMAX {
            for y in 0 ..< YMAX {
                drawCell(x,y)
            }
        }
        
        context.setShadow(offset:CGSize(width:0,height:0), blur:0, color:shadowColor.cgColor)
        drawText(5,SCREEN_YS-20,"Cheat",16,.black,0)
    }
    
    //MARK: - cellPosition
    
    func cellPosition(_ x:Int, _ y:Int) -> CGPoint {
        var pt = CGPoint()
        pt.x = ULcornerX + CGFloat(x) * CellSize * CellHopX
        pt.y = ULcornerY + CGFloat(y) * CellSize * CellHopY
        if !isOdd(y) { pt.x -= CellSize * 23/24 }
        return pt
    }
    
    //MARK: - touched
    
    func touched(_ pt:CGPoint) {
        func determineHexIndexFromTouch(_ pt:CGPoint) {
            cellX = NONE
            cellY = NONE
            
            for x in 0 ..< XMAX {
                for y in 0 ..< YMAX {
                    if x == XMAX-1 && isOdd(y) { continue }
                    
                    var cp = cellPosition(x,y)
                    cp.x -= 25
                    cp.y -= 25
                    let rect = CGRect(origin: cp, size: CGSize(width:50, height:50))
                    
                    if rect.contains(pt) {
                        cellX = x
                        cellY = y
                        return
                    }
                }
            }
        }
        
        var pt = pt
        pt.x *= SCREEN_XS / screenSize.width
        pt.y *= SCREEN_YS / screenSize.height
        
        cheatDisplay = false
        if pt.x < 50 && pt.y > 900  {
            cheatDisplay = true
            quartzView.setNeedsDisplay()
            return
        }
        
        determineHexIndexFromTouch(pt)
        
        if legalCellIndex(cellX,cellY) {
            if cell[cellX][cellY].display { // update userNumber
                userNumber = cell[cellX][cellY].number
            }
            else { // toggle userNumber
                cell[cellX][cellY].user = (cell[cellX][cellY].user == userNumber) ? NONE : userNumber
            }
        }
    }
}

