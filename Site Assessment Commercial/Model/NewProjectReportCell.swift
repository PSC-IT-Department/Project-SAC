//
//  NewProjectReportCell.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2018-12-06.
//  Copyright © 2018 chyapp.com. All rights reserved.
//

import UIKit
import ARKit
import RxCocoa
import RxSwift
import RxDataSources

enum NewProjectReportCellType: String, Codable {
    case ar              = "AR"
    case singleSelection = "Single Selection"
    case image           = "Image"
    case singleInput     = "Single Input"
    case twoInputs       = "Two Inputs"
    case threeInputs     = "Three Inputs"
    case notes           = "Notes"
}

class NewProjectReportCell: UICollectionViewCell {
}

class ARCell: UICollectionViewCell {
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var imageviewReference: UIImageView!
    
    @IBOutlet weak var arView: ARSCNView!
}

class SingleSelectionCell: UICollectionViewCell {
    @IBOutlet weak var imageviewReference: UIImageView!
    
    @IBOutlet var buttonGroup: [MyCheckBox]!
    
    @IBOutlet weak var labelKey: UILabel!
    
    var tapAction: ((MyCheckBox) -> Void)?
    
    @IBAction func buttonTapped(_ sender: MyCheckBox) {
        tapAction?(sender)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class ImageCell: UICollectionViewCell {
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var collectionView: ImageGalleryCollectionView!
    
    var tapAction: ((UIButton)->())?
    @IBAction func buttonTapped(_ sender: UIButton) {
        tapAction?(sender)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.collectionView.images = []
        self.collectionView.isUserInteractionEnabled = false
    }
        
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        
        layoutAttributes.bounds.size.height = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        
        return layoutAttributes
    }

}

class SingleInputCell: UICollectionViewCell {
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var textValue: UITextField!
}

class TwoInputsCell: UICollectionViewCell {
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var labelOperator: UILabel!
    @IBOutlet var textFields: [UITextField]!

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class ThreeInputsCell: UICollectionViewCell {
    @IBOutlet weak var labelKey: UILabel!
    
    @IBOutlet var labelOperators: [UILabel]!
    @IBOutlet var textFields: [UITextField]!

    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class NotesCell: UICollectionViewCell, UITextViewDelegate {
    var disposeBag = DisposeBag()

    @IBOutlet weak var textViewNotesHeight: NSLayoutConstraint!
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var textviewNotes: UITextView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.textviewNotes.text = "Notes: "
        self.textviewNotes.textColor = UIColor.lightGray
        self.textviewNotes.delegate = self
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        layoutAttributes.bounds.size.height = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height

        return layoutAttributes
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Notes: "
            textView.textColor = UIColor.lightGray
        }
        
        print("textViewDidEndEditing")
        
        textView.resignFirstResponder()
    }

}

class ImageGalleryCell: UICollectionViewCell {
    @IBOutlet weak var buttonView: UIButton!
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        layoutAttributes.bounds.size.height = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        
        return layoutAttributes
    }
}
