//
//  LocationPickerViewController.swift
//  ChatApp
//
//  Created by iOSTeam on 26/07/2022.
//

import UIKit
import CoreLocation
import MapKit

class LocationPickerViewController: UIViewController {
    
    public var completion: ((CLLocationCoordinate2D) ->Void)?
    
    private var coordinates: CLLocationCoordinate2D?
    
    //Có cho phép Pin Location và Click Button Send hay không
    private var isPickable: Bool
    
    let map: MKMapView = {
        let map = MKMapView()
        return map
    }()
    
    init(coordinates: CLLocationCoordinate2D?, isPickable: Bool) {
        self.coordinates = coordinates
        self.isPickable = isPickable
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarController?.tabBar.isHidden = true
        
        map.isUserInteractionEnabled = true
        view.addSubview(map)
        
        //Pin location và show button send
        if isPickable {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send",
                                                                style: .done,
                                                                target: self,
                                                                action: #selector(sendButtonClicked))
            let gesture = UITapGestureRecognizer(target: self,
                                                 action: #selector(tapOnMap(gesture:)))
            gesture.numberOfTouchesRequired = 1
            map.addGestureRecognizer(gesture)
        }
        //Hiển thị Location với Pin theo coordinates được truyền từ ChatViewController
        else {
            guard let coordinates = coordinates else {
                return
            }
            let pin = MKPointAnnotation()
            pin.coordinate = coordinates
            map.addAnnotation(pin)
        }
        
        
    }
    
    //CLick button Send
    @objc func sendButtonClicked() {
        guard let coordinates = coordinates else {
            let alert = UIAlertController(title: "Please Choose Your Location",
                                          message: "",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(alert, animated: true)
            return
        }
        completion?(coordinates)
    }
    
    //Tap vào Map
    @objc func tapOnMap(gesture: UITapGestureRecognizer) {
        let locationInView = gesture.location(in: map)
        let coordinates = map.convert(locationInView, toCoordinateFrom: map)
        self.coordinates = coordinates
        
        for anonation in map.annotations {
            map.removeAnnotation(anonation)
        }
        
        let pin = MKPointAnnotation()
        pin.coordinate = coordinates
        map.addAnnotation(pin)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        map.frame = view.bounds
    }

}
