//
//  SessionTableViewCell.swift
//  WWDCast
//
//  Created by Maksym Shcheglov on 05/07/16.
//  Copyright © 2016 Maksym Shcheglov. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SessionTableViewCell: RxTableViewCell, ReusableView, BindableView, NibProvidable {
    @IBOutlet private weak var thumbnailImage: UIImageView!
    @IBOutlet private weak var title: UILabel!
    @IBOutlet private weak var summary: UILabel!
//}
//
//extension SessionTableViewCell: BindableView {
    typealias ViewModel = SessionItemViewModel

    func bind(to viewModel: ViewModel) {
        self.title.text = viewModel.title
        self.summary.text = viewModel.summary
        _ = Observable.just(viewModel.thumbnailURL)
            .asObservable()
            .takeUntil(self.onPrepareForReuse)
            .bind(to: self.thumbnailImage.rx.imageURL)
        self.layoutMargins = UIEdgeInsets.zero
        self.separatorInset = UIEdgeInsets.zero
    }
}
