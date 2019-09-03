//
//  AddEventViewControllerCells.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-04-29.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import Foundation
import UIKit

import RxSwift
import RxCocoa
import RxBiBinding

import MapKit
import CoreLocation

class AETextCell: UITableViewCell {
    @IBOutlet weak var textField: UITextField!
    
    static let identifier = "AETextCell"
    private var disposeBag = DisposeBag()

    private var textValue = BehaviorRelay(value: "")
    
    var textValueChanged: ((String) -> Void)?

    func setupCell(item: AddEventDataViewModel) {
        textField.placeholder = item.key
        
        textField.returnKeyType = .done
        
        (textField.rx.text.orEmpty <-> textValue).disposed(by: disposeBag)
        
        textField.text = item.value

        textFieldDidChanged()
    }
    
    func textFieldDidChanged() {
        textValue.asDriver()
            .throttle(RxTimeInterval.milliseconds(3), latest: true)
            .drive(onNext: { [weak self] (text) in
                self?.textValueChanged?(text)
            })
            .disposed(by: disposeBag)
    }
    
    func textValueChanged(action: @escaping (String) -> Void) {
        textValueChanged = action
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()
        
        textField.text = nil
    }
}

protocol DatePickerDelegate: class {
    func didChangeDate(date: Date, indexPath: IndexPath)
}

class AEDatePickerCell: UITableViewCell {
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var labelValue: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!

    static let identifier = "AEDatePickerCell"
    
    var indexPath: IndexPath!
    weak var delegate: DatePickerDelegate?
    private var dateValue = BehaviorRelay(value: Date())

    var dateValueChanged: ((String) -> Void)?

    var disposeBag = DisposeBag()
    
    private func setupDatePicker() {
        let date = Date()
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let dateString = dateFormatter.string(from: date)
        
        guard let newDate = dateFormatter.date(from: dateString) else { return }
        
        datePicker.date = newDate
        datePicker.datePickerMode = .dateAndTime
    }

    func setupCell(item: AddEventDataViewModel) {
        labelKey.text = item.key
        labelValue.text = item.value
        
        setupDatePicker()
        
        (datePicker.rx.date <-> dateValue).disposed(by: disposeBag)
        
        dateValue.asDriver()
            .drive(onNext: { [weak self] (date) in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                
                let sheduleDate = formatter.string(from: date)
                self?.dateValueChanged?(sheduleDate)
                print("setupCell date = \(sheduleDate)")
            })
            .disposed(by: disposeBag)
    }
    
    func toggleShowDatePicker() {
        datePicker.isHidden = !datePicker.isHidden
    }
    
    func dateValueChanged(action: @escaping (String) -> Void) {
        dateValueChanged = action
    }
    
    @IBAction func datePickerChanged(_ sender: UIDatePicker) {
        delegate?.didChangeDate(date: sender.date, indexPath: indexPath)
    }
}

class AEMapViewCell: UITableViewCell {
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var labelValue: UILabel!
    
    private var disposeBag = DisposeBag()
    
    static let identifier = "AEMapViewCell"
    
    func setupCell(item: AddEventDataViewModel) {
        labelKey.text = item.key
        labelValue.text = item.value
    }
    
    func toggleShowMapView() {
//        mapView.isHidden = !mapView.isHidden
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }
}

class AENotesCell: UITableViewCell {
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var textView: UITextView!
    
    private var disposeBag = DisposeBag()

    static let identifier = "AENotesCell"
    
    var textValue = BehaviorRelay(value: "")
    
    var textValueChanged: ((String) -> Void)?

    func setupCell(item: AddEventDataViewModel) {
        labelKey.text = item.key
        (textView.rx.text.orEmpty <-> textValue).disposed(by: disposeBag)
        
        setupTextValueHandling()
        
        setupTextView(text: item.value)
    }
    
    func setupTextView(text: String?) {
        if let text = text, text != "" {
            textView.text = text
         }
        
        textView.returnKeyType = .done

    }
    
    func setupTextValueHandling() {
        textValue.asDriver()
            .throttle(RxTimeInterval.milliseconds(3), latest: true)
            .drive(onNext: { [weak self] (text) in
                if text.contains("\n") {
                    self?.textView.resignFirstResponder()
                    self?.textValueChanged?(text)
                }
            })
            .disposed(by: disposeBag)
    }
    
    func textValueChanged(action: @escaping (String) -> Void) {
        textValueChanged = action
    }
    
    func toggleShowTextView() {
//        textView.isHidden = !textView.isHidden
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()
        labelKey.text = nil
    }
    
}
