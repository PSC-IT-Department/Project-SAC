//
//  ProjectInformationViewController.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2018-11-23.
//  Copyright © 2018 chyapp.com. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

import MapKit

// https://www.thorntech.com/2016/01/how-to-search-for-location-using-apples-mapkit/
protocol HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark)
}

class ProjectInformationViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    private var titleString: String!
    private var prjData = SiteAssessmentDataStructure()

    private let locationManager = CLLocationManager()
    private var currentCoordinate: CLLocationCoordinate2D?
    fileprivate var selectedPin: MKPlacemark? = nil
    fileprivate var handleMapSearchDelegate: HandleMapSearch? = nil

    let disposeBag = DisposeBag()
    
    var observableViewModel: Observable<[ProjectInformationViewModel]>!

    override func viewDidLoad() {
        super.viewDidLoad()
    
//        configureLocationServices()

        setupView()
        setupViewModel()
        setupCell()
        setupStartButton()
    }

    static func instantiateFromStoryBoard(withProjectData data: SiteAssessmentDataStructure) -> ProjectInformationViewController {
        let viewController = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "ProjectInformationViewController") as! ProjectInformationViewController
        viewController.prjData = data
        viewController.titleString = data.prjInformation.projectAddress
        
        return viewController
    }
    
    @IBAction func buttonStartDidClicked(_ sender: Any) {
        let status = prjData.prjInformation.status
        
        if status == .completed {
            let viewController = ReviewViewController.instantiateFromStoryBoard(withProjectData: prjData)
            self.navigationController?.pushViewController(viewController, animated: true)
        } else {
            let viewController = NewProjectReportViewController.instantiateFromStoryBoard(withProjectData: prjData)
            self.navigationController?.pushViewController(viewController, animated: true)
        }
        
    }
    
    deinit {
        mapView.removeFromSuperview()
        mapView = nil
    }
}

extension ProjectInformationViewController {

    private func setupView() {
        self.title = titleString
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.setBackground()
    }
    
    private func setupViewModel() {
        let viewModel = prjData.prjInformation.toDictionary().compactMap { (key, value) -> ProjectInformationViewModel in
            return ProjectInformationViewModel(key: key, value: value)
        }
        
        observableViewModel = Observable.of(viewModel)
    }
    
    private func setupCell() {
        observableViewModel
            .bind(to: tableView.rx.items) { (tableView, row, data) in
                let cell = tableView.dequeueReusableCell(withIdentifier: "InformationCell", for: IndexPath(row: row, section: 0)) as! InformationCell

                cell.setupCell(viewModel: data)
                return cell
            }
            .disposed(by: disposeBag)
    }
    
    private func setupStartButton() {
        let status = prjData.prjInformation.status
        
        if status == .completed {
            startButton.setTitle("Review", for: .normal)
        } else {
            startButton.setTitle("Start", for: .normal)
        }
    }
}

extension ProjectInformationViewController: CLLocationManagerDelegate {
    private func configureLocationServices() {
        locationManager.delegate = self
        handleMapSearchDelegate = self

        let status = CLLocationManager.authorizationStatus()
        
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if status == .authorizedAlways || status == .authorizedWhenInUse {
            beginLocationUpdates(locationManager: locationManager)
        }
    }
    
    private func beginLocationUpdates(locationManager: CLLocationManager) {
        mapView.showsUserLocation = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        /*
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = prjData.prjInformation.projectAddress
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let response = response else {
                return
            }
            if let matchingItem = response.mapItems.first {
                let selectedItem = matchingItem.placemark

                self.zoomToLatestLocation(with: selectedItem.coordinate)
                self.handleMapSearchDelegate?.dropPinZoomIn(placemark: selectedItem)
            }
        }
         */

    }
    
    func parseAddress(selectedItem: MKPlacemark) -> String {
        // put a space between "4" and "Melrose Place"
        let firstSpace = (selectedItem.subThoroughfare != nil && selectedItem.thoroughfare != nil) ? " " : ""
        // put a comma between street and city/state
        let comma = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) && (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", " : ""
        // put a space between "Washington" and "DC"
        let secondSpace = (selectedItem.subAdministrativeArea != nil && selectedItem.administrativeArea != nil) ? " " : ""
        let addressLine = String(
            format:"%@%@%@%@%@%@%@",
            // street number
            selectedItem.subThoroughfare ?? "",
            firstSpace,
            // street name
            selectedItem.thoroughfare ?? "",
            comma,
            // city
            selectedItem.locality ?? "",
            secondSpace,
            // state
            selectedItem.administrativeArea ?? ""
        )
        return addressLine
    }
    
    @objc func getDirections(){
        if let selectedPin = selectedPin {
            let mapItem = MKMapItem(placemark: selectedPin)
            let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
            mapItem.openInMaps(launchOptions: launchOptions)
        }
    }
    
    private func zoomToLatestLocation(with coordinate: CLLocationCoordinate2D) {
        let zoomRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        mapView.setRegion(zoomRegion, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.first else { return }
        
        if currentCoordinate == nil {
            zoomToLatestLocation(with: latestLocation.coordinate)
        }
        
        currentCoordinate = latestLocation.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            beginLocationUpdates(locationManager: manager)
        }
    }
}

extension ProjectInformationViewController: HandleMapSearch {
    func dropPinZoomIn(placemark: MKPlacemark) {
        // cache the pin
        selectedPin = placemark
        // clear existing pins
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            annotation.subtitle = "\(city) \(state)"
        }
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
}

fileprivate extension Selector {
    static let getDirections = #selector(ProjectInformationViewController.getDirections)
}

extension ProjectInformationViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        pinView?.pinTintColor = UIColor.orange
        pinView?.canShowCallout = true
        let smallSquare = CGSize(width: 30, height: 30)
        let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
        button.setBackgroundImage(UIImage(named: "Navigation"), for: .normal)
        button.addTarget(self, action: .getDirections, for: .touchUpInside)
        pinView?.leftCalloutAccessoryView = button
        return pinView
    }
}

