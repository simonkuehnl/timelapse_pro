//
//  LaunchController.swift
//  Timelapse Pro
//
//  Created by Michael Steinbach on 16.12.17.
//  Copyright © 2017 flying-raspberry. All rights reserved.
//

import Foundation
final class LaunchScreenController: UIViewController, UITextFieldDelegate{
    override func viewDidLoad() {
        super.viewDidLoad()
        animate_images()
        _ = Timer.scheduledTimer(timeInterval: WaitingTime, target: self, selector: #selector(timeToMoveOn), userInfo: nil, repeats: false)
        _ = Timer.scheduledTimer(timeInterval: SleepingTime, target: self, selector: #selector(NumberCountUp), userInfo: nil, repeats: Repeat)

    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    var Repeat = true
    let WaitingTime = 2.5
    let SleepingTime = (1.5/360)
    var zwischen = 0
    
    @IBOutlet weak var LaunchScreenDial: UIImageView!
    
    @IBOutlet weak var NumberLaunchScreen: UILabel!
    
    func NumberCountUp() {
        if NumberLaunchScreen.text == "360" {
            Repeat = false
        }
        else{
            NumberLaunchScreen.text = String (zwischen+2)
        }
        zwischen=zwischen+2
    }
    
    func animate_images()
    {
        let myimgArr = ["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48","49","50","51","52","53","54","55","56","57","58","59","60","61","62","63","64","65","66","67","68","69","70","71","72","73","74","75","76"]
        var images = [UIImage]()
        
        for i in 0..<myimgArr.count
        {
            images.append(UIImage(named: myimgArr[i])!)
        }
        LaunchScreenDial.animationImages = images
        LaunchScreenDial.animationDuration = 1.5
        LaunchScreenDial.animationRepeatCount = 1
        LaunchScreenDial.startAnimating()
    }
    
    func timeToMoveOn() {
        //self.performSegue(withIdentifier: "FirstSeg", sender: self)
        //self.navigationController?.pushViewController(tabBarController!, animated: true)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.switchViewControllers()
    }
    
}
