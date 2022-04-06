//
//  ViewController.swift
//  MyBoard
//
//  Created by 金苇 on 2020/7/26.
//  Copyright © 2020 nuaaplase. All rights reserved.
//

import UIKit
import SwiftSocket

class ViewController: UIViewController {
    
    //MARK: Properties
    @IBOutlet weak var beganLocLabel: UILabel!
    @IBOutlet weak var movedLocLabel: UILabel!
    @IBOutlet weak var cancelledLocLabel: UILabel!
    
    @IBOutlet weak var beganForceLabel: UILabel!
    @IBOutlet weak var movedForceLabel: UILabel!
    @IBOutlet weak var cancelledForceLabel: UILabel!
    
    @IBOutlet weak var beganRadiusLabel: UILabel!
    @IBOutlet weak var movedRadiusLabel: UILabel!
    @IBOutlet weak var cancelledRadiusLabel: UILabel!
    
    @IBOutlet weak var touchTimeLabel: UILabel!
    
    
    var beganTime: TimeInterval = 0.0
    let CaliRowNum = 6
    let CaliColumnNum = 6
    let CaliCount = 36
    
    // 记录每一个校准点是否完成，完成以触屏开始为准
    var ifTouched = [Bool](repeating: false, count: 36)
    var deeperTimes = [Int](repeating: 0, count: 36)
    
    // 触控位置坐标
    var touchLocX = [CGFloat](repeating: 0, count: 36)
    var touchLocY = [CGFloat](repeating: 0, count: 36)
    
    var tooDeep = [Bool](repeating: false, count: 36)
    var tooShallow = [Bool](repeating: false, count: 36)
    
    var touchTime = [Double](repeating: 0, count: 36)
    
    var latestTime = [Double](repeating: 0, count: 1000)
    var latestIndex = 0
    
    var mutex = false
    
    // 最后一次校准是否完成，完成以触碰结束为准
    var finalTouchEnd = false
    // 当前进行到第几个校准点
    var touchedIndex = 0
    // 最终校准结果
    var caliRes: String = ""
     
    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // let circleCenter = [60, 60]
        let screenh = UIScreen.main.bounds.height
        let screenw = UIScreen.main.bounds.width
        let mid_x = screenw / 2
        let mid_y = screenh / 2
        print("屏幕高:\(screenh)")
        print("屏幕宽:\(screenw)")
        print("中间点为:\(mid_x),\(mid_y)")
        let radius = 300
        print(view.frame.width)
        print(view.frame.height)
        let x = Int(mid_x) - (radius / 2)
        let y = Int(mid_y) - (radius / 2)
        containerView.frame = CGRect(x: x, y: y, width: radius, height: radius)
        view.addSubview(containerView)
        
        
        beganLocLabel.isHidden = true
        movedLocLabel.isHidden = true
        cancelledLocLabel.isHidden = true

        beganForceLabel .isHidden = true
        movedForceLabel .isHidden = true
        cancelledForceLabel.isHidden = true
                
        beganRadiusLabel.isHidden = true
        movedRadiusLabel.isHidden = true
        cancelledRadiusLabel.isHidden = true
                
        touchTimeLabel.isHidden = true
        
        // let xInit = CGFloat(50)
        // let yInit = CGFloat(200)
        
        // var x = mid_x
        // var y = mid_y
        
        // let circleRadius = CGFloat(300)
        
        //drawCircle(centerX: mid_x, centerY: mid_y, radius: circleRadius)
//        for _ in 0..<6 {
//            for _ in 0..<6 {
//                drawCircle(centerX: x, centerY: y, radius: circleRadius)
//                x += 130
//            }
//            x = xInit
//            y += 130
//        }
        
        // drawCircle(centerX: mid_x, centerY: mid_y, radius: CGFloat(300))
        // drawCircle(centerX: mid_x, centerY: mid_y, radius: CGFloat(400))
        // drawCircle(centerX: mid_x, centerY: mid_y, radius: CGFloat(500))
        
        // let msg: String = "touch"
        // send(msg: msg)
        //drawOval()
        
        drawCircle(centerX: 0, centerY: 0, radius: CGFloat(5))
        
        let padding_x = 0.3 * 768
        let padding_y = 0.36 * 1024
        
        
        let x_indent = Int((768-padding_x)) / (CaliColumnNum - 1)
        let y_indent = Int((1024-padding_y)) / (CaliRowNum - 1)


        for i in 0..<CaliColumnNum{
            for j in 0..<CaliRowNum{
                let cx = CGFloat(padding_x / 2) + CGFloat(x_indent) * CGFloat(i)
                let cy = CGFloat(padding_y / 2) + CGFloat(y_indent) * CGFloat(j)
                // let xPic = (cx / 1242) * 768
                // let yPic = (cy / 2208) * 1024
                drawCircle(centerX: cx, centerY: cy, radius: CGFloat(5))
            }
        }
        
//        let column_indent = (2208 - 600) / 19
//        for j in 0..<20 {
//            let cx = CGFloat(200)
//            let cy = CGFloat(325) + CGFloat(column_indent) * CGFloat(j)
//            let xPic = (cx / 1242) * 768
//            let yPic = (cy / 2208) * 1024
//            drawCircle(centerX: xPic, centerY: yPic, radius: CGFloat(5))
//        }

        Thread.detachNewThread {
            print("detachNewThread creat a therad!")
            self.calibration()
        }
        
        
        // Do any additional setup after loading the view.
    }
    
    private func calibration() {
 
        send(msg: "start")
        
        for i in 0..<CaliCount{
            
            // 用于标记是否需要再进行一次该点的校准，当超过等待时间仍然没有检测到触控，则需要再检测一次该点
            var ifRepeat: Bool = true
            var repeatTimes: Int = 0
            while ifRepeat {
                print("当前检测第%d个校准点", i+1)
                
                let startTime = CFAbsoluteTimeGetCurrent()
                var currentTime = CFAbsoluteTimeGetCurrent()
                var waitTime = currentTime - startTime
                
                // print(ifTouched)
                print("------")
                // print(tooDeep)
                
                while ((waitTime < 8) && (!ifTouched[i])){
                    currentTime = CFAbsoluteTimeGetCurrent()
                    waitTime = currentTime - startTime
                    // print("waiting")
                }
                // 当前点的数据都记录完了才能往下判断，避免因为线程原因导致点的数据没记录完毕就往下执行了
                print("waiting over")
                while (!mutex) {
                    if (waitTime >= 8){
                        // 等待超时，代表这次没点到，不需要等待点的数据记录，因为这次不可能有数据
                        break;
                    }
                }
                
                mutex = false
                // print(tooDeep)
                // print("最终等了%f", waitTime)
                
                // 未检测到触控，加大深度
                if ((waitTime >= 8)) {
                    // print("时间到")
                    print("规定时间内未检测到触控，加大深度")
                    if (repeatTimes > 5) {
                        print("当前点加深次数过多，重新对该点进行触控")
                        repeatTimes = 0
                        send(msg: "reTouch" + String(repeatTimes))
                    } else {
                        repeatTimes = repeatTimes + 1
                        send(msg: "noTouch" + String(repeatTimes))
                    }
                    deeperTimes[i] = repeatTimes
                    ifRepeat = true
                    ifTouched[i] = false
                } else if (tooShallow[i]) {
                    // 触控力度过小，加大深度
                   print("触控力度过小，加大触控深度")
                   repeatTimes = repeatTimes + 1
                   deeperTimes[i] = repeatTimes
                   ifTouched[i] = false
                   tooShallow[i] = false
                   send(msg: "noTouch" + String(repeatTimes))
                   ifRepeat = true
                } else if (tooDeep[i]){
                    // 触控力度过大，减小深度
                    print("触控力度过大，减小触控深度")
                    repeatTimes = repeatTimes - 1
                    deeperTimes[i] = repeatTimes
                    ifTouched[i] = false
                    tooDeep[i] = false
                    send(msg: "tooDeep" + String(repeatTimes))
                    ifRepeat = true
                } else {
                    print("完美的触控")
                    ifRepeat = false
                    if (i != (CaliCount - 1)) {
                    send(msg: "next")
                    }
                }
                
            }
            
        }
        
        // 等待最后一次校准离开屏幕
        let startTime = CFAbsoluteTimeGetCurrent()
        var currentTime = CFAbsoluteTimeGetCurrent()
        var waitTime = currentTime - startTime
        print("完成全部校准")
        while waitTime < 5 && !finalTouchEnd {
            currentTime = CFAbsoluteTimeGetCurrent()
            waitTime = currentTime - startTime
        }
        for i in 0..<CaliCount{
            let sX = String(format: "%.3f", Double(touchLocX[i]))
            let sY = String(format: "%.3f", Double(touchLocY[i]))
            let time = String(format: "%.5f", touchTime[i])
            let deeperTime = deeperTimes[i]
            caliRes = caliRes + sX + " " + sY + " "
            caliRes = caliRes + time + " " + String(deeperTime)
            caliRes = caliRes + "\n"
        }
        print(caliRes)
        send(msg: "res" + caliRes)

        
    }
    
    private func send(msg: String) {
        let client = TCPClient(address: "192.168.1.104", port: 9000)
        switch client.connect(timeout: 10) {
          case .success:
            switch client.send(string: msg) {
              case .success:
                usleep(10000) // 等待0.01 秒
                guard let data = client.read(1024*10) else { return }
                if let response = String(bytes: data, encoding: .utf8) {
                  // print(response)
                }
              case .failure(let error):
                print("send error")
                // print(error)
            }
          case .failure(let error):
            print("connect error")
            print(error)
        }
    }
    
    private func drawOval() {
        
        let path = UIBezierPath(ovalIn: containerView.bounds)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.blue.cgColor
        shapeLayer.lineWidth = 3
        shapeLayer.strokeColor = UIColor.black.cgColor
        
        containerView.layer.addSublayer(shapeLayer)
    }
    
    private func drawCircle(centerX: CGFloat,centerY: CGFloat, radius: CGFloat) {
        let startX = centerX - radius / 2
        let startY = centerY - radius / 2
        let circleView = CircleView(frame: CGRect(x: startX, y: startY, width: radius, height: radius))
        view.addSubview(circleView)
    }
    
    private func drawCircleRed(centerX: CGFloat,centerY: CGFloat, radius: CGFloat) {
        let startX = centerX - radius / 2
        let startY = centerY - radius / 2
        let circleView = CircleViewRed(frame: CGRect(x: startX, y: startY, width: radius, height: radius))
        view.addSubview(circleView)
    }
    
    
    
    @IBAction func textInput(_ sender: UITextField) {
    }
    
    @IBAction func changeColor(_ sender: UIButton) {
        print("you press the button", terminator: " ")
    }
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        let touch = touches.first!
        // print("touch began")
        // print("\(touch.location(in: nil))", terminator: " ")
        
        beganTime = touch.timestamp
        let location = touch.location(in: nil)
        beganLocLabel.text = "位置为:\(location)"
        
        beganForceLabel.text = "按压力量为:\(touch.force)"
        
        beganRadiusLabel.text = "按压范围为:\(touch.majorRadius)"
        
        print("\(touch.timestamp)")
        
        let touchLoc = touch.location(in: view)
            
        // 2
        let circleRadius = CGFloat(150)
        // drawCircleRed(centerX: touchLoc.x, centerY: touchLoc.y, radius: circleRadius)
        drawCircleRed(centerX: touchLoc.x, centerY: touchLoc.y, radius: CGFloat(5))
        
        print("检测到 touch began")
        print(touchedIndex)
        print(location)
        
        
        // 只校准一定数目的点
        if (touchedIndex < CaliCount){
            let x = touch.location(in: nil).x
            let y = touch.location(in: nil).y
            if (touchedIndex > 0) {
                let diffX = x - touchLocX[touchedIndex - 1]
                let diffY = y - touchLocY[touchedIndex - 1]
                print("与上次点击位置的偏差为(\(diffX),\(diffY))")
                if (abs(diffX) < 20 && abs(diffY) < 20) {
                    print("此点为误触发")
                } else {
                    touchLocX[touchedIndex] = x
                    touchLocY[touchedIndex] = y
                }
            } else {
                // 第一次点击都会被记录
                touchLocX[touchedIndex] = x
                touchLocY[touchedIndex] = y
            }
            
            // touchedIndex = touchedIndex + 1
//            let sX = String(format: "%.3f", Double(x))
//            let sY = String(format: "%.3f", Double(y))
//            caliRes = caliRes + sX + " " + sY
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        let touch = touches.first!
        
        // print("touch moved")
        
        let location = touch.location(in: nil)
        movedLocLabel.text = "位置为\(location)"
        
        movedForceLabel.text = "按压力量为:\(touch.force)"
        
        movedRadiusLabel.text = "按压范围为:\(touch.majorRadius)"
        
        /*
        print("\(touch.force)")
        print("\(touch.majorRadius)")
        print("\(touch.timestamp)")
        */
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        let touch = touches.first!
        print("touch cancelled")
        
        let location = touch.location(in: nil)
        
        cancelledLocLabel.text = "位置为\(location)"
        
        cancelledForceLabel.text = "按压力量为:\(touch.force)"
        
        cancelledRadiusLabel.text = "按压范围为:\(touch.majorRadius)"
        
        /*
        print("\(touch.force)")
        print("\(touch.majorRadius)")
        print("\(touch.timestamp)")
        */
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let touch = touches.first
        
        let touchTimeOne = (touch?.timestamp ?? 1000) - beganTime
        
        // print(beganTime)
        // print(touch?.timestamp ?? 1000)
        // print(touchTime)
        
        // 触控时间需要小于一定值

        print("触摸位置为:(\(touchLocX[touchedIndex]), \(touchLocY[touchedIndex]))", terminator: " ")
        print("触摸时间为:\(touchTimeOne)")
        
        
        let thisTime = touch!.timestamp
        
        print("触摸时刻为:\(thisTime)")
        
        let lastTime = latestTime[latestIndex]

        latestIndex = latestIndex + 1
        latestTime[latestIndex] = thisTime
        
        if ((thisTime - lastTime) < 1) {
            print("该点为 end 误触")
            return
        }
        
        
        
        latestTime[latestIndex] = touch!.timestamp
        // 避免一次触控触发多次点击事件
        if (touchLocX[touchedIndex] != 0 && touchLocY[touchedIndex] != 0) {
            print(touchedIndex)
            print(touchLocX[touchedIndex])
            print(touchLocY[touchedIndex])
            if (touchTimeOne < 0.5 && touchTimeOne > 0.20) {
                print("合格点")
                // print("touchedIndex\(touchedIndex)")
                ifTouched[touchedIndex] = true
                touchTime[touchedIndex] = touchTimeOne
                touchedIndex = touchedIndex + 1
            } else if(touchTimeOne <= 0.20) {
                print("过浅的点")
                ifTouched[touchedIndex] = true
                tooShallow[touchedIndex] = true
            } else {
                print("过深的点")
                ifTouched[touchedIndex] = true
                tooDeep[touchedIndex] = true
                // touchedIndex = touchedIndex - 1
            }
            
            mutex = true
        }
                        
        // touchTimeLabel.text = "触摸时间为:\(touchTime)"
//        let sT = String(format: "%.5f", touchTime)
//        caliRes = caliRes + " " + sT + " "
//        caliRes = caliRes + String(deeperTimes[touchedIndex - 1]) + "\n"
        if(ifTouched[CaliCount-1]) {
            finalTouchEnd = true
        }
        
    }



}

