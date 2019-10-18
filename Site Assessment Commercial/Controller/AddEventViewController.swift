//
//  AddEventViewController.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-04-29.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa
import RxDataSources

import RxBiBinding

import MapKit
import CoreLocation

private typealias AddEventSection = AnimatableSectionModel<String, AddEventDataViewModel>

enum AddEventCellType: String, Codable {
    case textCell       = "AETextCell"
    case notesCell      = "AENotesCell"
    case mapViewCell    = "AEMapViewCell"
    case datePickerCell = "AEDatePickerCell"
}

struct AddEventDataViewModel: IdentifiableType, Equatable {
    var identity: Int?
    
    var key: String!
    var value: String?
    var type: AddEventCellType!

    init(key: String!, value: String? = nil, type: AddEventCellType!) {
        self.key = key
        self.value = value
        self.type = type
    }
}

struct DataModel {
    var name: String!
    var startTime: String?
    var endTime: String?
    var location: String?
    var notes: String?
    
    init(name: String, startTime: String? = nil, endTime: String? = nil,
         location: String? = nil, notes: String? = nil) {
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.notes = notes
    }
}

@objc protocol AddEventViewControllerDelegate {
    func passingScheduleDate(date: String?)
}

class AddEventViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIButton!
    
    static let identifier = "AddEventViewController"

    private var disposeBag = DisposeBag()
    
    private let locationManager = CLLocationManager()
    private var currentCoordinate: CLLocationCoordinate2D?
    private var projectLocation: CLLocation!

    private var sections = BehaviorRelay(value: [AddEventSection]())
    
    private var eventData: DataModel!
    
    private var projectAddress: String!
    
    weak var delegate: AddEventViewControllerDelegate!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupEventData()
        setupView()
        setupViewModel()
        setupDataSource()
        setupCellTapHandling()
        setupDelegate()
    }
    
    static func instantiateFromStoryBoard(_ prjAddr: String) -> AddEventViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let identifier = AddEventViewController.identifier
        if let vc =  storyboard.instantiateViewController(withIdentifier: identifier) as? AddEventViewController {
            vc.projectAddress = prjAddr
            return vc
        } else {
            return nil
        }
    }
    
    deinit {
        print("AddEventViewController deinit")
    }
    
    @IBAction func scheduleButtonDidClicked(_ sender: UIButton) {
        
        GoogleService.shared.fetchCalendarList(onCompleted: {
            [weak self, weak googleService = GoogleService.shared] list, _ in
            if let list = list, let calendarID = list.first,
                let eventData = self?.eventData {
               
                googleService?.calendarId = calendarID
                
                googleService?.checkDuplicateEventsByEventName(eventName: eventData.name)
                
                googleService?.addEventToCalendar(calendarId: calendarID,
                                                        name: eventData.name, startTime: eventData.startTime,
                                                        endTime: eventData.endTime, notes: eventData.notes) {
                                                            [weak self] (error) in
                    if let err = error {
                        print("Error = \(err.localizedDescription)")
                        return
                    } else {
                        self?.delegate.passingScheduleDate(date: eventData.startTime)
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            }
        })
    }
}

extension AddEventViewController {
    
    private func setupEventData() {
        eventData = DataModel(name: projectAddress, location: projectAddress)
    }
    
    private func setupView() {
        title = "Add New Event"
        
        // https://stackoverflow.com/questions/28733936/change-color-of-back-button-in-navigation-bar @Tiep Vu Van
        navigationController?.navigationBar.tintColor = UIColor(named: "PSC_Blue")
        
        // Auto Layout
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 42.0
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        setBackground()
    }
    
    private func setupDataSource() {
        let (configureCell, titleForSection) = tableViewDataSourceUI()
        
        let reloadDataSource = RxTableViewSectionedReloadDataSource<AddEventSection>(
            configureCell: configureCell,
            titleForHeaderInSection: titleForSection
        )
        
        sections.asObservable()
            .bind(to: tableView.rx.items(dataSource: reloadDataSource))
            .disposed(by: disposeBag)
    }
    
    private func tableViewDataSourceUI() -> (
        TableViewSectionedDataSource<AddEventSection>.ConfigureCell,
        TableViewSectionedDataSource<AddEventSection>.TitleForHeaderInSection
        ) {
            return ({ [weak self] (_, tv, ip, i) in

                guard let type = i.type else { return UITableViewCell() }
                switch type {
                case .textCell:
                    let identifier = AETextCell.identifier
                    let cellIdentifier = CellIdentifier<AETextCell>(reusableIdentifier: identifier)
                    let cell = tv.dequeueReusableCellWithIdentifier(identifier: cellIdentifier, forIndexPath: ip)
                    
                    cell.setupCell(item: i)
                    
                    cell.textValueChanged { [weak self] (text) in
                        self?.eventData.name = text
                    }

                    return cell
                case .datePickerCell:
                    let identifier = AEDatePickerCell.identifier
                    let cellIdentifier = CellIdentifier<AEDatePickerCell>(reusableIdentifier: identifier)
                    let cell = tv.dequeueReusableCellWithIdentifier(identifier: cellIdentifier, forIndexPath: ip)
                    cell.setupCell(item: i)
                    
                    cell.dateValueChanged { [weak self] (datetime) in
                        print("dateValueChanged = \(datetime), i.key = \(String(describing: i.key))")
                        
                        if let key = i.key {
                            if key == "Start Time" {
                                self?.eventData.startTime = datetime
                            } else {
                                self?.eventData.endTime = datetime
                            }
                        }
                    }
                    
                    return cell
                case .mapViewCell:
                    let identifier = AEMapViewCell.identifier
                    let cellIdentifier = CellIdentifier<AEMapViewCell>(reusableIdentifier: identifier)
                    let cell = tv.dequeueReusableCellWithIdentifier(identifier: cellIdentifier, forIndexPath: ip)
                    
                    self?.locationManager.delegate = self
                    
                    cell.setupCell(item: i)
                    return cell

                case .notesCell:
                    let identifier = AENotesCell.identifier
                    let cellIdentifier = CellIdentifier<AENotesCell>(reusableIdentifier: identifier)
                    let cell = tv.dequeueReusableCellWithIdentifier(identifier: cellIdentifier, forIndexPath: ip)
                    
                    cell.setupCell(item: i)
                    
                    cell.textValueChanged { [weak tv, weak self] text in
                        print("text = \(text)")
                        
                        self?.eventData.notes = text
                        
                        tv?.beginUpdates()
                        tv?.endUpdates()
                    }
                    
                    return cell
                }
                
            }, { (ds, section) -> String? in
                    return ds[section].model
                }
            )
    }
    
    private func setupViewModel() {
        let viewModel = [
            AddEventDataViewModel(key: "Event Name", value: projectAddress, type: .textCell),
            AddEventDataViewModel(key: "Start Time", type: .datePickerCell),
            AddEventDataViewModel(key: "End Time", type: .datePickerCell),
            AddEventDataViewModel(key: "Location", value: projectAddress, type: .mapViewCell),
            AddEventDataViewModel(key: "Notes", type: .notesCell)
        ]
        
        let addEventSections = [AddEventSection(model: "", items: viewModel)]
    
        sections.accept(addEventSections)
    }
    
    private func setupCellTapHandling() {
        tableView
            .rx
            .itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                defer { self?.tableView.deselectRow(at: indexPath, animated: true) }
                
                guard let item = self?.sections.value.first?.items[indexPath.row],
                    let type = item.type
                    else { return }
                switch type {
                case .datePickerCell:
                    guard let cell = self?.tableView.cellForRow(at: indexPath) as? AEDatePickerCell else { return }
                    cell.toggleShowDatePicker()

                    UIView.animate(withDuration: 0.3, animations: { [weak self] in
                        self?.tableView.beginUpdates()
                        self?.tableView.endUpdates()
                    })
                    
                case .mapViewCell:
                    guard let cell = self?.tableView.cellForRow(at: indexPath) as? AEMapViewCell else { return }
                    cell.toggleShowMapView()
                    
                    UIView.animate(withDuration: 0.3, animations: { [weak self] in
                        self?.tableView.beginUpdates()
                        self?.tableView.endUpdates()
                    })
                    
                case .textCell:
                    break
                    
                case .notesCell:
                    guard let cell = self?.tableView.cellForRow(at: indexPath) as? AENotesCell else { return }
                    cell.toggleShowTextView()
                    
                    self?.tableView.beginUpdates()
                    self?.tableView.endUpdates()
                }
                
            })
            .disposed(by: disposeBag)
    }

    private func setupDelegate() {
        tableView
            .rx
            .setDelegate(self)
            .disposed(by: disposeBag)
    }
}

// UITableViewDelegate
extension AddEventViewController: UITableViewDelegate {
    
}

extension AddEventViewController: CLLocationManagerDelegate {
}

extension AddEventViewController: MKMapViewDelegate {
    
}
