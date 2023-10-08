//
//  CustomTableViewCell.swift
//  FirstCopy
//
//  Created by Sraavan Chevireddy on 08/10/23.
//

import UIKit

class CustomTableViewCell: UITableViewCell {
    
    private var lbl_title: UILabel!
    private var lbl_subtitle: UILabel!
    private var lbl_sellingPrice: UILabel!
    private var lbl_basePrice: UILabel!
    
    private var lbl_size: UILabel!
    
    var model: ProductInfo? {
        didSet {
            if let model = model {
                lbl_title.text = model.title ?? ""
                lbl_subtitle.text = model.productId ?? ""
                lbl_basePrice.text = "Sale Price \n$ \(model.salePrice)"
                lbl_sellingPrice.text = "List Price \n$ \(model.listPrice)"
                
                lbl_size.text = model.size ?? ""
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        loadUIComponents()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func loadUIComponents() {
        lbl_title = {
            let modalView = UILabel()
            modalView.font = .systemFont(ofSize: 18, weight: .black, width: .standard)
            return modalView
        }()
        
        lbl_subtitle = {
            let modalView = UILabel()
            modalView.font = .preferredFont(forTextStyle: .body)
            modalView.textColor = .secondaryLabel
            return modalView
        }()
        
        lbl_sellingPrice = {
            let modalView = UILabel()
            modalView.font = .boldSystemFont(ofSize: 10)
            return modalView
        }()
        
        lbl_basePrice = {
            let modalView = UILabel()
            modalView.font = .boldSystemFont(ofSize: 10)
            return modalView
        }()
        
        lbl_size = {
            let modalView = UILabel()
            modalView.font = UIFont(name: "Arial Rounded MT Bold", size: 22)
            return modalView
        }()
        
        [lbl_title, lbl_subtitle, lbl_basePrice, lbl_sellingPrice, lbl_size].forEach({contentView.addSubview($0)})
        
        lbl_title.setupAutoAnchors(top: contentView.topAnchor, leading: contentView.leadingAnchor, bottom: nil, trailing: contentView.trailingAnchor)
        lbl_subtitle.setupAutoAnchors(top: lbl_title.bottomAnchor, leading: contentView.leadingAnchor, bottom: nil, trailing: contentView.trailingAnchor)
        
        lbl_basePrice.setupAutoAnchors(top: lbl_subtitle.bottomAnchor, leading: contentView.leadingAnchor, bottom: nil, trailing: contentView.trailingAnchor)
        lbl_sellingPrice.setupAutoAnchors(top: lbl_basePrice.bottomAnchor, leading: contentView.leadingAnchor, bottom: nil, trailing: contentView.trailingAnchor)
        
        lbl_size.setupAutoAnchors(top: lbl_sellingPrice.bottomAnchor, leading: contentView.leadingAnchor, bottom: contentView.bottomAnchor, trailing: contentView.trailingAnchor)
    }
}
