//
//  Timelapse Pro
//
//
//  Created by Simon Kühnl and Michael Steinbach
//  Copyright (c) 2017 Flying Raspberry. All rights reserved.
//

import UIKit
import CoreBluetooth
import QuartzCore
import HGCircularSlider

var recLinks = 2
var recRechts = 15

var playLinks = 0
var playRechts = 40

var intLinks = 0
var intRechts = 27

enum MessageOption: Int {
    case noLineEnding,
    newline,
    carriageReturn,
    carriageReturnAndNewline
}

enum ReceivedMessageOption: Int {
    case none,
    newline
}

final class SerialViewController: UIViewController, CAAnimationDelegate, UITextFieldDelegate, BluetoothSerialDelegate {
    
    
    //***************************************ab hier geht es los***********************************************
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // init serial
        adjustments.isHidden = true
        updateText(links: recLinks, rechts: recRechts, kürzel1: "h", kürzel2: "m", label: recTimeLabel)
        updateInt()
        updateText(links: playLinks, rechts: playRechts, kürzel1: "m", kürzel2: "s", label: playTimeLabel)
        cameraPosition.startThumbImage = UIImage(named: "Foto")
        serial = BluetoothSerial(delegate: self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(SerialViewController.reloadView), name: NSNotification.Name(rawValue: "reloadStartViewController"), object: nil)
        degreeslider.minimumValue = 0
        degreeslider.maximumValue = 360
        degreeslider.endPointValue = 180.0
        setColor(180)
        // UI White
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        _ = Timer.scheduledTimer(timeInterval: 180.0, target: self, selector: #selector(akkuCheck), userInfo: nil, repeats: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        akkuCheck()
        updatePresetRec()
        updatePresetPlay()
        updatePresetIntervall()
    }
    
    @IBOutlet weak var cameraPosition: RangeCircularSlider!
    
    var receiveMessage = ""{
        willSet{
            akkuAnzeige()
            
        }
    }
    
    
    @IBAction func cameraPosition(_ sender: RangeCircularSlider) {
       
        _ = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(sendCameraPostitionToDevice), userInfo: nil, repeats: false)
    }
    
    func sendCameraPostitionToDevice(){
        var msg = ""
        var intmsg = Int(cameraPosition.startPointValue)
        switch intmsg {
        case 0..<10:
            msg = "00"+String(intmsg)+"22"
        case 10..<100:
            msg = "0"+String(intmsg)+"22"
        default:
            msg = String(intmsg)+"22"
        }
        msgLable.text = msg
        serial.sendMessageToDevice(msg)
        receiveMessage = ""
    }
    
    
    @IBOutlet weak var adjustments: UIView!
    @IBOutlet weak var text: UILabel! // Feld in dem die Beschreibung von REC-TIME, PLAY-TIME und INTERVAL steht
    
    
    //********** degreeSlider - großer Slider in der Mitte *********
    
    @IBOutlet weak var degreeView: UILabel!
    @IBOutlet weak var degreeslider: RangeCircularSlider!
    @IBAction func degreeslider(_ sender: RangeCircularSlider) {
        var text: Int
        
        if sender.startPointValue > sender.endPointValue{
            text = Int(360-sender.startPointValue+sender.endPointValue)
            setColor(text)
            degreeView.text = String(text)
        }else{
            text = Int(sender.endPointValue-sender.startPointValue)
            setColor(text)
            degreeView.text = String(text)
        }
        
    }
    
    func setColor(_ value: Int){
        var newValue = value
        if ( value % 2 != 0){
            newValue = value - 1
        }
        newValue = newValue / 2
        switch newValue {
        case 0..<52:
            var red = 0 + newValue
            var x = Float(red)
            setSliderColor(UIColor( red: CGFloat(x/255.0),
                                    green: CGFloat(255/255.0),
                                    blue: CGFloat(153/255.0),
                                    alpha: CGFloat(1.0) ))
        case 52..<119:
            var blue = 153 + (newValue - 51)
            var x = Float(blue)
            setSliderColor(UIColor( red: CGFloat(51/255.0),
                                    green: CGFloat(255/255.0),
                                    blue: CGFloat(x/255.0),
                                    alpha: CGFloat(1.0) ))
        case 119..<134:
            var green = 255 - (newValue - 118)
            var x = Float(green)
            setSliderColor(UIColor( red: CGFloat(51/255.0),
                                    green: CGFloat(x/255.0),
                                    blue: CGFloat(220/255.0),
                                    alpha: CGFloat(1.0) ))
        default:
            var red = 51 + (newValue - 133)
            var x = Float(red)
            setSliderColor(UIColor( red: CGFloat(x/255.0),
                                    green: CGFloat(240/255.0),
                                    blue: CGFloat(220/255.0),
                                    alpha: CGFloat(1.0) ))
        }
    }
    
    func setSliderColor(_ color: UIColor){
        degreeslider.trackFillColor = color
        degreeslider.endThumbTintColor = color
        degreeslider.startThumbTintColor = color
    }
    //**************************************************************
    
    
    
    //********** zum anzeigen und justieren der REC TIME ***********
    

    @IBOutlet weak var adjustLinks: UILabel!
    @IBOutlet weak var adjustRechts: UILabel!
    
    @IBOutlet weak var recTime: UIButton!
    @IBOutlet weak var recTimeLabel: UILabel!
    @IBOutlet weak var recSliderLinks: UISlider!
    @IBOutlet weak var recSliderRechts: UISlider!
    @IBOutlet weak var recTimeRechts: UIButton!
    @IBOutlet weak var recTimeLinks: UIButton!
    
    @IBAction func recTime(_ sender: UIButton) {
        playSliderLinks.isHidden = true
        playSliderRechts.isHidden = true
        playTimeLinks.isHidden = true
        playTimeRechts.isHidden = true
        intSliderLinks.isHidden = true
        intSliderRechts.isHidden = true
        intervalLinks.isHidden = true
        intervalRechts.isHidden = true
        recSliderLinks.isHidden = false
        recSliderRechts.isHidden = true
        recTimeLinks.isHidden = false
        recTimeRechts.isHidden = false
        adjustLinks.text = String(recLinks)+"h"
        adjustRechts.text = String(recRechts)+"m"
        adjustRechts.textColor = UIColor.white
        adjustLinks.textColor = UIColor.green
        sender.setTitleColor(UIColor.green, for: .normal)
        playTime.setTitleColor(UIColor.white, for: .normal)
        interval.setTitleColor(UIColor.white, for: .normal)
        adjustments.isHidden = false
        text.text = "Bestimme wie lange deine Timelapse aufgenommen werden soll."
        sliderSetup(min: 0, max: 24, start: recLinks, sender: recSliderLinks)
    }
    
    @IBAction func recTimeLinks(_ sender: UIButton) {
        adjustRechts.textColor = UIColor.white
        adjustLinks.textColor = UIColor.green
        recSliderLinks.isHidden = false
        recSliderRechts.isHidden = true
        sliderSetup(min: 0, max: 24, start: recLinks, sender: recSliderLinks)
    }
    
    @IBAction func recTimeRechts(_ sender: UIButton) {
        adjustRechts.textColor = UIColor.green
        adjustLinks.textColor = UIColor.white
        recSliderLinks.isHidden = true
        recSliderRechts.isHidden = false
        sliderSetup(min: 0, max: 59, start: recRechts, sender: recSliderRechts)
    }
    
    @IBAction func recSliderRechts(_ sender: UISlider) {
        adjustRechts.text = String(Int(sender.value))+"m"
        recRechts = ((Int)(sender.value))
        updateText(links: recLinks, rechts: ((Int)(sender.value)), kürzel1: "h", kürzel2: "m", label: recTimeLabel)
        updatePlay()
    }
    
    @IBAction func recSliderLinks(_ sender: UISlider) {
        adjustLinks.text = String(Int(sender.value))+"h"
        recLinks = ((Int)(sender.value))
        updateText(links: ((Int)(sender.value)), rechts: recRechts, kürzel1: "h", kürzel2: "m", label: recTimeLabel)
        updatePlay()
    }
    
    func updatePresetRec(){
        updateText(links: recLinks, rechts: recRechts, kürzel1: "h", kürzel2: "m", label: recTimeLabel)
    }
    
    //**************************************************************
    
    
    
    //********** zum anzeigen und justieren der PLAY TIME **********
    

    
    @IBOutlet weak var playTime: UIButton!
    @IBOutlet weak var playTimeLabel: UILabel!
    @IBOutlet weak var playSliderLinks: UISlider!
    @IBOutlet weak var playSliderRechts: UISlider!
    @IBOutlet weak var playTimeRechts: UIButton!
    @IBOutlet weak var playTimeLinks: UIButton!
    
    
    @IBAction func playTime(_ sender: UIButton) {
        recSliderLinks.isHidden = true
        recSliderRechts.isHidden = true
        recTimeLinks.isHidden = true
        recTimeRechts.isHidden = true
        intSliderLinks.isHidden = true
        intSliderRechts.isHidden = true
        intervalLinks.isHidden = true
        intervalRechts.isHidden = true
        playSliderLinks.isHidden = false
        playSliderRechts.isHidden = true
        playTimeLinks.isHidden = false
        playTimeRechts.isHidden = false
        adjustLinks.text = String(playLinks)+"m"
        adjustRechts.text = String(playRechts)+"s"
        adjustRechts.textColor = UIColor.white
        adjustLinks.textColor = UIColor.green
        sender.setTitleColor(UIColor.green, for: .normal)
        recTime.setTitleColor(UIColor.white, for: .normal)
        interval.setTitleColor(UIColor.white, for: .normal)
        adjustments.isHidden = false
        text.text = "Bestimme wie lange deine Timelapse am Ende werden soll."
        recSliderLinks.isHidden = true
        recSliderRechts.isHidden = true
        sliderSetup(min: 0, max: 59, start: playLinks, sender: playSliderLinks)
    }
    @IBAction func playTimeRechts(_ sender: UIButton) {
        adjustRechts.textColor = UIColor.green
        adjustLinks.textColor = UIColor.white
        playSliderLinks.isHidden = true
        playSliderRechts.isHidden = false
        sliderSetup(min: 0, max: 59, start: playRechts, sender: playSliderRechts)
    }
    @IBAction func playTimeLinks(_ sender: UIButton) {
        adjustRechts.textColor = UIColor.white
        adjustLinks.textColor = UIColor.green
        playSliderLinks.isHidden = false
        playSliderRechts.isHidden = true
        sliderSetup(min: 0, max: 59, start: playLinks, sender: playSliderLinks)
    }
    
    
    @IBAction func playSliderRechts(_ sender: UISlider) {
        adjustRechts.text = String(Int(sender.value))+"s"
        playRechts = ((Int)(sender.value))
        updateText(links: playLinks, rechts: ((Int)(sender.value)), kürzel1: "m", kürzel2: "s", label: playTimeLabel)
        switch intLinks {
        case 0:
            intervaltimetosend = "00"
        case 0..<10:
            intervaltimetosend = "0" + String(intLinks)
        case 10..<100:
            intervaltimetosend = String(intLinks)
        default:
            intervaltimetosend = "00"
        }
        switch intRechts {
        case 0:
            intervaltimetosend += "00"
        case 0..<10:
            intervaltimetosend += "0" + String(intRechts)
        case 10..<100:
            intervaltimetosend += String(intRechts)
        default:
            intervaltimetosend += "00"
        }
    }
    @IBAction func playSliderLinks(_ sender: UISlider) {
        adjustLinks.text = String(Int(sender.value))+"m"
        playLinks = ((Int)(sender.value))
        updateText(links: ((Int)(sender.value)), rechts: playRechts, kürzel1: "m", kürzel2: "s", label: playTimeLabel)
        updateInt()
        switch intLinks {
        case 0:
            intervaltimetosend = "00"
        case 0..<10:
            intervaltimetosend = "0" + String(intLinks)
        case 10..<100:
            intervaltimetosend = String(intLinks)
        default:
            intervaltimetosend = "00"
        }
        switch intRechts {
        case 0:
            intervaltimetosend += "00"
        case 0..<10:
            intervaltimetosend += "0" + String(intRechts)
        case 10..<100:
            intervaltimetosend += String(intRechts)
        default:
            intervaltimetosend += "00"
        }
    }
    
    func updatePresetPlay(){
        updateText(links: playLinks, rechts: playRechts, kürzel1: "m", kürzel2: "s", label: playTimeLabel)
    }
    
    //**************************************************************
    
    
    
    //********** zum anzeigen und justieren des INTERVALS **********
    

    
    @IBOutlet weak var interval: UIButton!
    @IBOutlet weak var intervalLabel: UILabel!
    @IBOutlet weak var intSliderLinks: UISlider!
    @IBOutlet weak var intSliderRechts: UISlider!
    @IBOutlet weak var intervalRechts: UIButton!
    @IBOutlet weak var intervalLinks: UIButton!
    
    @IBAction func intervalRechts(_ sender: UIButton) {
        adjustRechts.textColor = UIColor.green
        adjustLinks.textColor = UIColor.white
        intSliderLinks.isHidden = true
        intSliderRechts.isHidden = false
        sliderSetup(min: 0, max: 59, start: intRechts, sender: intSliderRechts)
    }
    @IBAction func intervalLinks(_ sender: UIButton) {
        adjustRechts.textColor = UIColor.white
        adjustLinks.textColor = UIColor.green
        intSliderLinks.isHidden = false
        intSliderRechts.isHidden = true
        sliderSetup(min: 0, max: 59, start: intLinks, sender: intSliderLinks)
    }
    
    @IBAction func interval(_ sender: UIButton) {
        adjustLinks.text = String(intLinks)
        adjustRechts.text = String(intRechts)
        recSliderLinks.isHidden = true
        recSliderRechts.isHidden = true
        recTimeLinks.isHidden = true
        recTimeRechts.isHidden = true
        playSliderLinks.isHidden = true
        playSliderRechts.isHidden = true
        playTimeLinks.isHidden = true
        playTimeRechts.isHidden = true
        intSliderLinks.isHidden = false
        intSliderRechts.isHidden = true
        intervalLinks.isHidden = false
        intervalRechts.isHidden = false
        adjustLinks.text = String(intLinks)+"m"
        adjustRechts.text = String(intRechts)+"s"
        adjustRechts.textColor = UIColor.white
        adjustLinks.textColor = UIColor.green
        sender.setTitleColor(UIColor.green, for: .normal)
        playTime.setTitleColor(UIColor.white, for: .normal)
        recTime.setTitleColor(UIColor.white, for: .normal)
        adjustments.isHidden = false
        text.text = "Bestimme in welchem Abstand ein Bild gemacht werden soll."
        sliderSetup(min: 0, max: 59, start: intLinks, sender: intSliderLinks)
    }
    
    @IBAction func intSliderRechts(_ sender: UISlider) {
        adjustRechts.text = String(Int(sender.value))+"s"
        intRechts = ((Int)(sender.value))
        updateText(links: intLinks, rechts: ((Int)(sender.value)), kürzel1: "m", kürzel2: "s", label: intervalLabel)
        updatePlay()
        switch intLinks {
        case 0:
            intervaltimetosend = "00"
        case 0..<10:
            intervaltimetosend = "0" + String(intLinks)
        case 10..<100:
            intervaltimetosend = String(intLinks)
        default:
            intervaltimetosend = "00"
        }
        switch intRechts {
        case 0:
            intervaltimetosend += "00"
        case 0..<10:
            intervaltimetosend += "0" + String(intRechts)
        case 10..<100:
            intervaltimetosend += String(intRechts)
        default:
            intervaltimetosend += "00"
        }
    }
    
    @IBAction func intSliderLinks(_ sender: UISlider) {
        adjustLinks.text = String(Int(sender.value))+"m"
        intLinks = ((Int)(sender.value))
        updateText(links: ((Int)(sender.value)), rechts: recRechts, kürzel1: "m", kürzel2: "s", label: intervalLabel)
        updatePlay()
        switch intLinks {
        case 0:
            intervaltimetosend = "00"
        case 0..<10:
            intervaltimetosend = "0" + String(intLinks)
        case 10..<100:
            intervaltimetosend = String(intLinks)
        default:
            intervaltimetosend = "00"
        }
        switch intRechts {
        case 0:
            intervaltimetosend += "00"
        case 0..<10:
            intervaltimetosend += "0" + String(intRechts)
        case 10..<100:
            intervaltimetosend += String(intRechts)
        default:
            intervaltimetosend += "00"
        }
    }
    
    func updatePresetIntervall(){
        updateText(links: intLinks, rechts: intRechts, kürzel1: "m", kürzel2: "s", label: intervalLabel)
    }
    //**************************************************************
    
    
    
    //************* Methode zum einstellen der Slider **************
    
    func sliderSetup (min: Int, max: Int, start: Int, sender: UISlider){
        sender.minimumValue = Float(min)
        sender.maximumValue = Float(max)
        sender.value = Float(start)
    }
    
    //**************************************************************
    
    @IBAction func Retry(_ sender: UIButton) {
    }
    
    //************** Drehrichtung einstellen************************
    var turn = 0
    
    @IBAction func rotation(_ sender: UIButton) {
        if (sender.currentImage == #imageLiteral(resourceName: "rotation right")){
            sender.setImage(#imageLiteral(resourceName: "rotation left"), for: .normal)
            msgLable.text = "99"
            serial.sendMessageToDevice("99")
            let x = degreeslider.startPointValue
            let y = degreeslider.endPointValue
            let f1 = degreeslider.startThumbTintColor
            let f2 = degreeslider.startThumbStrokeColor
            let f3 = degreeslider.startThumbStrokeHighlightedColor
            let f4 = degreeslider.endThumbTintColor
            let f5 = degreeslider.endThumbStrokeColor
            let f6 = degreeslider.endThumbStrokeHighlightedColor
            degreeslider.startPointValue = y
            degreeslider.endPointValue = x
            degreeslider.startThumbTintColor = f4
            degreeslider.startThumbStrokeColor = f5
            degreeslider.startThumbStrokeHighlightedColor = f6
            degreeslider.endThumbTintColor = f1
            degreeslider.endThumbStrokeColor = f2
            degreeslider.endThumbStrokeHighlightedColor = f3
            if degreeslider.startPointValue > degreeslider.endPointValue{
                var setToString = Int(360-degreeslider.startPointValue+degreeslider.endPointValue)
                degreeView.text = String (setToString)
                setColor(setToString)
            }else{
                var setToString = Int(degreeslider.endPointValue-degreeslider.startPointValue)
                degreeView.text = String(setToString)
                setColor(setToString)
            }
            turn = 1
            
        }
        else{
            sender.setImage(#imageLiteral(resourceName: "rotation right"), for: .normal)
            msgLable.text = "88"
            serial.sendMessageToDevice("88")
            let x = degreeslider.startPointValue
            let y = degreeslider.endPointValue
            let f1 = degreeslider.startThumbTintColor
            let f2 = degreeslider.startThumbStrokeColor
            let f3 = degreeslider.startThumbStrokeHighlightedColor
            let f4 = degreeslider.endThumbTintColor
            let f5 = degreeslider.endThumbStrokeColor
            let f6 = degreeslider.endThumbStrokeHighlightedColor
            degreeslider.startPointValue = y
            degreeslider.endPointValue = x
            degreeslider.startThumbTintColor = f4
            degreeslider.startThumbStrokeColor = f5
            degreeslider.startThumbStrokeHighlightedColor = f6
            degreeslider.endThumbTintColor = f1
            degreeslider.endThumbStrokeColor = f2
            degreeslider.endThumbStrokeHighlightedColor = f3
            if degreeslider.startPointValue > degreeslider.endPointValue{
                var setToString = Int(360-degreeslider.startPointValue+degreeslider.endPointValue)
                degreeView.text = String(setToString)
                setColor(setToString)
            }else{
                var setToString = Int(degreeslider.endPointValue-degreeslider.startPointValue)
                degreeView.text = String(setToString)
                setColor(setToString)
            }
            turn = 0
        }
    }
    
    
    //********************* Start und Vorschau *********************
    
    @IBOutlet weak var msgLable: UILabel!
    
    func sendStartSignal(){
        var x = Int (degreeslider.startPointValue)
        var sx = "String"
        var y = Int (degreeslider.endPointValue)
        var sy = "String"
        switch x {
        case 0..<10:
            sx = "00"+String(x)
        case 10..<100:
            sx = "0"+String(x)
        default:
            sx = String(x)
        }
        switch y {
        case 0..<10:
            sy = "00"+String(y)
        case 10..<100:
            sy = "0"+String(y)
        default:
            sy = String(y)
        }
        var msg = "String"
        if(turn == 1){
            msg = sy+sx+"11"
        }
        if(turn == 0){
            msg = sx+sy+"11"
        }
        msgLable.text = msg
        serial.sendMessageToDevice(msg)
        startbutton.setBackgroundImage(#imageLiteral(resourceName: "stop"), for: .normal)
    }
    
    @IBAction func start(_ sender: UIButton) {
        sendRecTime()
    }
    
    
    var isRotating = false
    var shouldStopRotating = false
    
    
    @IBAction func vorschau(_ sender: UIButton) {
        var x = Int (degreeslider.startPointValue)
        var sx = "String"
        var y = Int (degreeslider.endPointValue)
        var sy = "String"
        switch x {
        case 0..<10:
            sx = "00"+String(x)
        case 10..<100:
            sx = "0"+String(x)
        default:
            sx = String(x)
        }
        switch y {
        case 0..<10:
            sy = "00"+String(y)
        case 10..<100:
            sy = "0"+String(y)
        default:
            sy = String(y)
        }
        var msg = "String"
        if(turn == 1){
            msg = sy+sx+"33"
        }
        if(turn == 0){
            msg = sx+sy+"33"
        }
        msgLable.text = msg
        serial.sendMessageToDevice(msg)
        if !akku.isHidden == true{
        vorschaubutton.isEnabled = false
        if self.isRotating == false {
            self.vorschaubutton.rotate360Degrees(completionDelegate: self)
            self.isRotating = true
        }
        }
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if self.shouldStopRotating == false {
            self.vorschaubutton.rotate360Degrees(completionDelegate: self)
        } else {
            self.reset()
        }
    }
    
    func reset() {
        self.isRotating = false
        self.shouldStopRotating = false
    }
    
    //**************************************************************
    
    
    
    //******** Methoden zum updaten der justierbaren Zeiten ********
    
    func updateText (links: Int, rechts: Int, kürzel1: String, kürzel2: String, label: UILabel){
        if links == 0{
            label.text = String(rechts)+kürzel2
        }
        else if rechts == 0{
            label.text = String(links)+kürzel1
        }
        else{
            label.text = String(links)+kürzel1+String(rechts)+kürzel2
        }
    }
    var rectimetosend = "0215"
    var intervaltimetosend = "0007"
    func updatePlay (){
        var fps = 30
        var recInSec = Double(((recLinks * 60 + recRechts) * 60))
        switch recLinks {
        case 0:
            rectimetosend = "00"
        case 1..<10:
            rectimetosend = "0" + String(recLinks)
        case 10..<100:
            rectimetosend = String(recLinks)
        default:
            rectimetosend = "00"
        }
        switch recRechts {
        case 0:
            rectimetosend += "00"
        case 1..<10:
            rectimetosend += "0" + String(recRechts)
        case 10..<100:
            rectimetosend += String(recRechts)
        default:
            rectimetosend += "00"
        }
        var intInSec = Double(((intLinks * 60 + intRechts) * fps))
        var updatePlay = recInSec / intInSec
        if (updatePlay > 1.2){
            var roundUpdatePlay = Int (round(updatePlay))
            playLinks = Int(roundUpdatePlay / 60)
            playRechts = Int(roundUpdatePlay % 60)
            updateText(links: playLinks, rechts: playRechts, kürzel1: "m", kürzel2: "s", label: playTimeLabel)
        }else{
            let alert = UIAlertController(title: "Interval zu lange", message: "Du kannst das Interval nicht weiter verlängen, da du sonst nicht genügend Bilder für die fertige Timelapse bekommst", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func updateInt (){
        var fps = 30
        var recInSec = Double(((recLinks * 60 + recRechts) * 60))
        switch recLinks {
        case 0:
            rectimetosend = "00"
        case 1..<10:
            rectimetosend = "0" + String(recLinks)
        case 10..<100:
            rectimetosend = String(recLinks)
        default:
            rectimetosend = "00"
        }
        switch recRechts {
        case 0:
            rectimetosend += "00"
        case 1..<10:
            rectimetosend += "0" + String(recRechts)
        case 10..<100:
            rectimetosend += String(recRechts)
        default:
            rectimetosend += "00"
        }
        var playInSec = Double(((playLinks * 60 + playRechts) * fps))
        var updateInt = recInSec / playInSec
        if (updateInt > 1.2){
            var roundUpdateInt = Int (round(updateInt))
            intLinks = Int(roundUpdateInt / 60)
            intRechts = Int(roundUpdateInt % 60)
            updateText(links: intLinks, rechts: intRechts, kürzel1: "m", kürzel2: "s", label: intervalLabel)
        }else{
            let alert = UIAlertController(title: "Interval zu gering", message: "Du kannst die Playtime nicht weiter verringen, denn ein Interval < 1 ist nicht möglich", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    func sendRecTime() {
        switch recLinks {
        case 0:
            rectimetosend = "00"
        case 1..<10:
            rectimetosend = "0" + String(recLinks)
        case 10..<100:
            rectimetosend = String(recLinks)
        default:
            rectimetosend = "00"
        }
        switch recRechts {
        case 0:
            rectimetosend += "00"
        case 1..<10:
            rectimetosend += "0" + String(recRechts)
        case 10..<100:
            rectimetosend += String(recRechts)
        default:
            rectimetosend += "00"
        }
        let msg = rectimetosend + "44"
        msgLable.text = msg
        serial.sendMessageToDevice(msg)
    }
    
    func sendintervall(){
        switch intLinks {
        case 0:
            intervaltimetosend = "00"
        case 0..<10:
            intervaltimetosend = "0" + String(intLinks)
        case 10..<100:
            intervaltimetosend = String(intLinks)
        default:
            intervaltimetosend = "00"
        }
        switch intRechts {
        case 0:
            intervaltimetosend += "00"
        case 0..<10:
            intervaltimetosend += "0" + String(intRechts)
        case 10..<100:
            intervaltimetosend += String(intRechts)
        default:
            intervaltimetosend += "00"
        }
        let msg1 = intervaltimetosend + "55"
        msgLable.text = msg1
        serial.sendMessageToDevice(msg1)
    }
    //**************************************************************
    
    
    @IBAction func close(_ sender: UIButton) {
        adjustments.isHidden = true
        recTime.setTitleColor(UIColor.white, for: .normal)
        playTime.setTitleColor(UIColor.white, for: .normal)
        interval.setTitleColor(UIColor.white, for: .normal)
    }
    
    //***********************Akku stand zeigen***************

    @IBOutlet weak var akku: UIImageView!
    
    func akkuCheck(){
        serial.sendMessageToDevice("77")
       _ = Timer.scheduledTimer(timeInterval: 0.6, target: self, selector: #selector(akkuAnzeige), userInfo: nil, repeats: false)
    }
    
    @IBOutlet weak var startbutton: UIButton!
    
    @IBOutlet weak var vorschaubutton: UIButton!
    
    func akkuAnzeige(){
        switch receiveMessage.lowercased() as NSString{
        case let x where x.range(of: "a").length != 0:
            akku.isHidden = false
            akku.image = #imageLiteral(resourceName: "batterie 100")
        case let x where x.range(of: "b").length != 0:
            akku.isHidden = false
            akku.image = #imageLiteral(resourceName: "batterie 75")
        case let x where x.range(of: "c").length != 0:
            akku.isHidden = false
            akku.image = #imageLiteral(resourceName: "batterie 50")
        case let x where x.range(of: "d").length != 0:
            akku.isHidden = false
            akku.image = #imageLiteral(resourceName: "batterie 25")
        case let x where x.range(of: "r").length != 0:
            sendintervall()
        case let x where x.range(of: "i").length != 0:
            _ = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(sendStartSignal), userInfo: nil, repeats: false)
        case let x where x.range(of: "zz").length != 0:
                vorschaubutton.isEnabled = true
                self.shouldStopRotating = true
        case let x where x.range(of: "xx").length != 0:
            startbutton.setBackgroundImage(#imageLiteral(resourceName: "start"), for: .normal)
        default: break
            
        }
    }
    
    //***************************************Bluetooth nicht verändern***********************************************
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    //MARK: BluetoothSerialDelegate
    
    @IBOutlet weak var test2lable: UILabel!
    
    
    func serialDidReceiveString(_ message: String) {
        // add the received text to the textView, optionally with a line break at the end
        test2lable.text = message
        receiveMessage = String(message)
        akkuAnzeige()
    }
    
    func reloadView() {
        // in case we're the visible view again
        serial.delegate = self
    }
    
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
        reloadView()
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud?.mode = MBProgressHUDMode.text
        hud?.labelText = "Disconnected"
        hud?.hide(true, afterDelay: 1.0)
    }
    
    func serialDidChangeState() {
        if serial.centralManager.state != .poweredOn {
            let hud = MBProgressHUD.showAdded(to: view, animated: true)
            hud?.mode = MBProgressHUDMode.text
            hud?.labelText = "Bluetooth turned off"
            hud?.hide(true, afterDelay: 1.0)
        }
    }
    
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if !serial.isReady {
            let alert = UIAlertController(title: "Not connected", message: "What am I supposed to send this to?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: { action -> Void in self.dismiss(animated: true, completion: nil) }))
            present(alert, animated: true, completion: nil)
            return true
        }
        
        // send the message to the bluetooth device
        // but fist, add optionally a line break or carriage return (or both) to the message
        let pref = UserDefaults.standard.integer(forKey: MessageOptionKey)
        // send the message and clear the textfield
        return true
    }
    
    
    
    //MARK: IBActions
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

