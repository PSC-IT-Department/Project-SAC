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

import NotificationBannerSwift

class ProjectInformationViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    private var prjData = SiteAssessmentDataStructure()

    private let locationManager = CLLocationManager()
    private var currentCoordinate: CLLocationCoordinate2D?
    private var projectLocation: CLLocation!

    private let disposeBag = DisposeBag()
    
    private var viewModel: [ProjectInformationViewModel]!
    private var sections = BehaviorRelay(value: [ProjectInformationViewModel]())

    override func viewDidLoad() {
        super.viewDidLoad()
    
        configureLocationServices()
        
        setupView()
        setupViewModel()
        setupCell()
        setupCellTapHandling()
        setupStartButton()
        setupStartButtonTapHandling()
    }

    static func instantiateFromStoryBoard() -> ProjectInformationViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let controller = storyboard.instantiateViewController(withClass: ProjectInformationViewController.self) {
            controller.prjData = DataStorageService.shared.retrieveCurrentProjectData()
            return controller
        } else {
            return nil
        }
    }
    
    deinit {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeFromSuperview()
        mapView = nil

        print("ProjectInformationViewController deinit")
    }
}

extension ProjectInformationViewController {

    private func setupView() {
        title = prjData.prjInformation.projectAddress
        
        // https://stackoverflow.com/questions/28733936/change-color-of-back-button-in-navigation-bar @Tiep Vu Van
        navigationController?.navigationBar.tintColor = UIColor(named: "PSC_Blue")

        // Auto Layout
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 42.0
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        setBackground()
    }
    
    private func setupViewModel() {
        viewModel = [
            ProjectInformationViewModel(key: "Project Address", value: prjData.prjInformation.projectAddress),
            ProjectInformationViewModel(key: "Status", value: prjData.prjInformation.status.rawValue),
            ProjectInformationViewModel(key: "Type", value: prjData.prjInformation.type.rawValue),

            ProjectInformationViewModel(key: "Customer Name", value: prjData.prjInformation.customerName),
            ProjectInformationViewModel(key: "Email", value: prjData.prjInformation.email),
            ProjectInformationViewModel(key: "Phone Number", value: prjData.prjInformation.phoneNumber),

            ProjectInformationViewModel(key: "Schedule Date", value: prjData.prjInformation.scheduleDate),
            ProjectInformationViewModel(key: "Assigned Date", value: prjData.prjInformation.assignedDate)
        ]
        
        sections.accept(viewModel)
    }
    
    private func setupCell() {
        sections.asObservable()
            .bind(to: tableView.rx.items) { (tableView, row, data) in
                
                let indexPath = IndexPath(row: row, section: 0)
                let cell = tableView.dequeueReusableCell(withClass: InformationCell.self, for: indexPath)

                cell.setupCell(viewModel: data)
                
                if data.key == "Schedule Date" {
                    cell.contentView.layer.borderColor = UIColor(red: 0.50, green: 0.55, blue: 0.59, alpha: 1.0).cgColor
                    cell.contentView.layer.borderWidth = 1
                }
                
                return cell
            }
            .disposed(by: disposeBag)
        
    }
    
    private func setupCellTapHandling() {
        tableView
            .rx
            .itemSelected
            .subscribe(onNext: { [unowned self] indexPath in
                self.tableView.deselectRow(at: indexPath, animated: true)
                let row = self.viewModel[indexPath.row]
                if row.key == "Schedule Date",
                    let prjAddr = self.prjData.prjInformation.projectAddress {
                    if let vc =
                        AddEventViewController.instantiateFromStoryBoard(prjAddr) {
                        
                        vc.delegate = self
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }
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
    
    private func setupStartButtonTapHandling() {
        startButton
            .rx
            .tap
            .subscribe(onNext: { [unowned self] (_) in
                let status = self.prjData.prjInformation.status
                switch status {
                case .completed?:
                    if let vc = ReviewViewController.instantiateFromStoryBoard(withProjectData: self.prjData) {
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                default:
                    if let vc = ContainerViewController.instantiateFromStoryBoard() {
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }
            })
            .disposed(by: disposeBag)
    }
}

extension ProjectInformationViewController: CLLocationManagerDelegate {
    private func configureLocationServices() {
        locationManager.delegate = self
        mapView.delegate = self
        
        let option = DataStorageService.shared.retrieveMapTypeOption()
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
        geoCoder.geocodeAddressString(prjData.prjInformation.projectAddress) {[weak self] (placemarks, _) in
            guard let placemarks = placemarks,
                let location = placemarks.first?.location
                else { return }
            
            self?.setupLocation(with: location)
        }
    }
    
    private func setupLocation(with location: CLLocation) {
        
        projectLocation = location
        
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

extension ProjectInformationViewController: AddEventViewControllerDelegate {
    func passingScheduleDate(date: String?) {
        if let date = date {
            prjData.prjInformation.scheduleDate = date
            
            DataStorageService.shared.storeData(withData: prjData, onCompleted: nil)
            
            setupViewModel()
            
            let banner = StatusBarNotificationBanner(title: "Measurement has been scheduled.", style: .success)
            banner.show()
        }
    }
}
