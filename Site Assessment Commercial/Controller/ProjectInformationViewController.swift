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
import Contacts

class ProjectInformationViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    private var titleString: String!
    private var prjData = SiteAssessmentDataStructure()

    private let locationManager = CLLocationManager()
    private var currentCoordinate: CLLocationCoordinate2D?
    private var projectLocation: CLLocation!

    let disposeBag = DisposeBag()
    
    var observableViewModel: Observable<[ProjectInformationViewModel]>!

    override func viewDidLoad() {
        super.viewDidLoad()
    
        configureLocationServices()

        setupView()
        setupViewModel()
        setupCell()
        setupCellTapHandling()
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
        // https://stackoverflow.com/questions/28733936/change-color-of-back-button-in-navigation-bar @Tiep Vu Van
        self.navigationController?.navigationBar.tintColor = UIColor(named: "PSC_Blue")
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.setBackground()
    }
    
    private func setupViewModel() {
        let viewModel = [
            ProjectInformationViewModel(key: "Project Address", value: prjData.prjInformation.projectAddress),
            ProjectInformationViewModel(key: "Status",          value: prjData.prjInformation.status.rawValue),
            ProjectInformationViewModel(key: "Type",            value: prjData.prjInformation.type.rawValue),
            ProjectInformationViewModel(key: "Schedule Date",   value: prjData.prjInformation.scheduleDate),
            ProjectInformationViewModel(key: "Assigned Date",   value: prjData.prjInformation.assignedDate)
        ]
        
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
    
    private func setupCellTapHandling() {
        tableView
            .rx
            .itemSelected
            .subscribe(onNext: { _ in
                guard let indexPath = self.tableView.indexPathForSelectedRow else { return }
                self.tableView.deselectRow(at: indexPath, animated: true)
            })
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
        mapView.delegate = self
        
        let option = DataStorageService.sharedDataStorageService.retrieveMapTypeOption()
        mapView.mapType = MKMapType(rawValue: option.rawValue)!

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
        
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(prjData.prjInformation.projectAddress) { (placemarks, error) in
            guard let placemarks = placemarks,
                let location = placemarks.first?.location
                else { return }
            
            self.setupLocation(with: location)
        }
    }
    
    private func setupLocation(with location: CLLocation) {
        
        self.projectLocation = location
        
        let annotation = MKPointAnnotation()
        
        annotation.coordinate = location.coordinate
        annotation.title = prjData.prjInformation.projectAddress
        
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(annotation)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location.coordinate, span: span)
        
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.first else { return }
    
        currentCoordinate = latestLocation.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            beginLocationUpdates(locationManager: manager)
        }
    }
}

extension ProjectInformationViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        let identifier = "marker"
        var view: MKMarkerAnnotationView

        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            as? MKMarkerAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: 5)
            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        return view
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                 calloutAccessoryControlTapped control: UIControl) {
        
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        
        let addressDict = [CNPostalAddressStreetKey: prjData.prjInformation.projectAddress!]
        let placeMark = MKPlacemark(coordinate: projectLocation.coordinate, addressDictionary: addressDict)
        let mapItem = MKMapItem(placemark: placeMark)
        
        mapItem.openInMaps(launchOptions: launchOptions)
    }

}
