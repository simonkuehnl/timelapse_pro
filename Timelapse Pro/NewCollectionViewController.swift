//
//  NewCollectionViewController.swift
//  Timelapse Pro
//
//  Created by Michael Steinbach on 19.12.17.
//  Copyright © 2017 flying-raspberry. All rights reserved.
//

import Foundation
import UIKit
class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    let reuseIdentifier = "cell" // also enter this string as the cell identifier in the storyboard
    var items = ["Sunset", "Person"]
    var images = [#imageLiteral(resourceName: "Sunset"),#imageLiteral(resourceName: "Personen")]
    
    
    // MARK: - UICollectionViewDataSource protocol
    
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! MyCollectionViewCell
        
        // Use the outlet in our custom class to get a reference to the UILabel in the cell
        cell.myLabel.text = self.items[indexPath.item]
        cell.PresetsImage.image = self.images[indexPath.item]
        return cell
    }
    
    // MARK: - UICollectionViewDelegate protocol
    
    func changeToTabBar0 (){
        self.tabBarController?.selectedIndex = 0
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // handle tap events
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        var index = indexPath.item
        switch index {
        case 0:
            hud?.mode = MBProgressHUDMode.text
            hud?.labelText = self.items[indexPath.item]+" selected"
            hud?.hide(true, afterDelay: 1.5)
            recLinks = 0
            recRechts = 45
            playLinks = 0
            playRechts = 9
            intLinks = 0
            intRechts = 10
            _ = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(changeToTabBar0), userInfo: nil, repeats: false)
        case 1:
            hud?.mode = MBProgressHUDMode.text
            hud?.labelText = self.items[indexPath.item]+" selected"
            hud?.hide(true, afterDelay: 1.5)
            recLinks = 0
            recRechts = 20
            playLinks = 0
            playRechts = 13
            intLinks = 0
            intRechts = 3
            _ = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(changeToTabBar0), userInfo: nil, repeats: false)
        default:
            print("nichts")
        }
    }
}
