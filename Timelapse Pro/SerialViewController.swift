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

final class SerialViewController: UIViewController, UITextFieldDelegate, BluetoothSerialDelegate {
    
    
    //***************************************ab hier geht es los***********************************************
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // init serial
        adjustments.isHidden = true
        updateText(links: recLinks, rechts: recRechts, kürzel1: "h", kürzel2: "m", label: recTimeLabel)
        updateInt()
        updateText(links: playLinks, rechts: playRechts, kürzel1: "m", kürzel2: "s", label: playTimeLabel)
        cameraPosition.midThumbImage = UIImage(named: "Foto")
        serial = BluetoothSerial(delegate: self)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(SerialViewController.reloadView), name: NSNotification.Name(rawValue: "reloadStartViewController"), object: nil)
        
        
        // UI White
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        akkuCheck()
    }
    
    
    
    
    
    
    
    
    @IBOutlet weak var cameraPosition: MidPointCircularSlider!
    var receiveMessage = ""
    
    @IBAction func cameraPosition(_ sender: MidPointCircularSlider) {
        var msg = ""
        if receiveMessage != ""{
            var intmsg = Int(sender.midPointValue)
            switch intmsg {
            case 0..<10:
                msg = "00"+String(intmsg)+"1"
            case 10..<100:
                msg = "0"+String(intmsg)+"1"
            default:
                msg = String(intmsg)+"1"
            }
            msgLable.text = msg
            serial.sendMessageToDevice(msg)
            receiveMessage = ""
        }
        else{
        }
        
    }
    
    
    @IBOutlet weak var adjustments: UIView!
    @IBOutlet weak var text: UILabel! // Feld in dem die Beschreibung von REC-TIME, PLAY-TIME und INTERVAL steht
    
    
    //********** degreeSlider - großer Slider in der Mitte *********
    
    @IBOutlet weak var degreeView: UILabel!
    @IBOutlet weak var degreeslider: RangeCircularSlider!
    @IBAction func degreeslider(_ sender: RangeCircularSlider) {
        sender.minimumValue = 0
        sender.maximumValue = 360
        
        if sender.startPointValue > sender.endPointValue{
            degreeView.text = String(Int(360-sender.startPointValue+sender.endPointValue))
        }else{
            degreeView.text = String(Int(sender.endPointValue-sender.startPointValue))
        }
    }
    
    //**************************************************************
    
    
    
    //********** zum anzeigen und justieren der REC TIME ***********
    
    var recLinks = 2
    var recRechts = 15
    @IBOutlet weak var adjustLinks: UILabel!
    @IBOutlet weak var adjustRechts: UILabel!
    
    @IBOutlet weak var recTime: UIButton!
    @IBOutlet weak var recTimeLabel: UILabel!
    @IBOutlet weak var recSliderLinks: UISlider!
    @IBOutlet weak var recSliderRechts: UISlider!
    @IBOutlet weak var recTimeRechts: UIButton!
    @IBOutlet weak var recTimeLinks: UIButton!
    
    @IBAction func recTime(_ sender: UIButton) {
        akkuCheck()
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
    
    //**************************************************************
    
    
    
    //********** zum anzeigen und justieren der PLAY TIME **********
    
    var playLinks = 0
    var playRechts = 40
    
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
    }
    @IBAction func playSliderLinks(_ sender: UISlider) {
        adjustLinks.text = String(Int(sender.value))+"m"
        playLinks = ((Int)(sender.value))
        updateText(links: ((Int)(sender.value)), rechts: playRechts, kürzel1: "m", kürzel2: "s", label: playTimeLabel)
        updateInt()
    }
    
    
    //**************************************************************
    
    
    
    //********** zum anzeigen und justieren des INTERVALS **********
    
    var intLinks = 0
    var intRechts = 27
    
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
    }
    
    @IBAction func intSliderLinks(_ sender: UISlider) {
        adjustLinks.text = String(Int(sender.value))+"m"
        intLinks = ((Int)(sender.value))
        updateText(links: ((Int)(sender.value)), rechts: recRechts, kürzel1: "m", kürzel2: "s", label: intervalLabel)
        updatePlay()
    }
    
    //**************************************************************
    
    
    
    //************* Methode zum einstellen der Slider **************
    
    func sliderSetup (min: Int, max: Int, start: Int, sender: UISlider){
        sender.minimumValue = Float(min)
        sender.maximumValue = Float(max)
        sender.value = Float(start)
    }
    
    //**************************************************************
    
    
    
    //********************* Start und Vorschau *********************
    
    @IBOutlet weak var msgLable: UILabel!
    
    @IBAction func start(_ sender: Any) {
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
        var recTime = recLinks*60+recRechts
        var StringRecTime = String(recTime)
        if recTime < 10{
            StringRecTime = "0"+String(recTime)
        }
        var msg = sx+sy+StringRecTime+"0"
        msgLable.text = msg
        serial.sendMessageToDevice(msg)
        
    }
    
    @IBAction func vorschau(_ sender: Any) {
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
        var msg = sx+sy+"3"
        msgLable.text = msg
        serial.sendMessageToDevice(msg)
        
        
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
    
    func updatePlay (){
        var fps = 30
        var recInSec = Double(((recLinks * 60 + recRechts) * 60))
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
    
    
    //**************************************************************
    
    
    @IBAction func close(_ sender: UIButton) {
        adjustments.isHidden = true
        recTime.setTitleColor(UIColor.white, for: .normal)
        playTime.setTitleColor(UIColor.white, for: .normal)
        interval.setTitleColor(UIColor.white, for: .normal)
    }
    
    //***********************Akku stand zeigen***************
    @IBOutlet weak var akkuAnzeige: UIProgressView!
    
    func akkuCheck(){
        serial.sendMessageToDevice("77777777")
        switch receiveMessage{
        case "100":
            akkuAnzeige(kategorie: 1)
        case "75":
            akkuAnzeige(kategorie: 2)
        case "50":
            akkuAnzeige(kategorie: 3)
        case "25":
            akkuAnzeige(kategorie: 4)
        default:
            let x = 0
        }
    }
    
    func akkuAnzeige(kategorie: Int){
        
        switch kategorie{
        case 4:
            akkuAnzeige.progress = 0.2
            akkuAnzeige.progressTintColor = UIColor.red
        case 3:
            akkuAnzeige.progress = 0.5
            akkuAnzeige.progressTintColor = UIColor.green
        case 2:
            akkuAnzeige.progress = 0.7
            akkuAnzeige.progressTintColor = UIColor.green
        default:
            akkuAnzeige.progress = 1.0
            akkuAnzeige.progressTintColor = UIColor.green
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
        receiveMessage = message
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

