//
//  SearchResultsViewController.swift
//  ObjectDetection
//
//  Created by Joshua Newnham on 14/05/2018.
//  Copyright © 2018 Joshua Newnham. All rights reserved.
//

import UIKit

class SearchResultsViewController: UIViewController {
    
    var searchCriteria : [ObjectBounds]?
    
    let photoSearcher = PhotoSearcher()
    
    var searchResults : [SearchResult]?
    
    var collectionView : UICollectionView?
    
    var objectDetectionImageView : ObjectDetectionImageView?
    
    weak var activityIndicatorView : UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        photoSearcher.delegate = self 
        
        self.initUI()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
}

// MARK: - search

extension SearchResultsViewController{
    
    func startSearch(){
        if let activityIndicatorView = self.activityIndicatorView{
            self.view.bringSubviewToFront(activityIndicatorView)
            activityIndicatorView.startAnimating()
        }
        
        photoSearcher.asyncSearch(searchCriteria: self.searchCriteria)
        
    }
}

// MARK: - UI Actions

extension SearchResultsViewController{
    
    @objc func onCloseButtonTapped(_ sender:UIButton){
        self.dismiss(animated: true) {
            
        }
    }
}

// MARK: - PhotoSearcherDelegate

extension SearchResultsViewController : PhotoSearcherDelegate{
    
    func onPhotoSearcherCompleted(status: Int, result:[SearchResult]?){
        // Stop animating activity indiactor
        self.activityIndicatorView?.stopAnimating()
        
        self.searchResults = result
        
        self.collectionView?.reloadData()
    }
}

// MARK: - User Interface

extension SearchResultsViewController{
    
    func initUI(){
        
        // Add activity indicator
        let activityIndicatorView = UIActivityIndicatorView(style: .gray)
        activityIndicatorView.center = self.view.center
        activityIndicatorView.hidesWhenStopped = true
        self.view.addSubview(activityIndicatorView)
        self.activityIndicatorView = activityIndicatorView
        
        // Create close button
        let closeButtonImage = UIImage(named: "left-arrow")
        let closeDownButtonImage = UIImage(named: "left-arrow_down")
        let closeButtonSize = CGSize(
            width: self.view.bounds.width * 0.08,
            height: self.view.bounds.width * 0.08 * (closeButtonImage!.size.height / closeButtonImage!.size.width))
        let closeButton = UIButton(
            frame:CGRect(
                x: (closeButtonSize.width * 0.3),
                y: UIApplication.shared.statusBarFrame.height + 10,
                width: closeButtonSize.width,
                height: closeButtonSize.height))
        self.view.addSubview(closeButton)
        closeButton.setImage(closeButtonImage, for: .normal)
        closeButton.setImage(closeDownButtonImage, for: .highlighted)
        closeButton.addTarget(
            self,
            action: #selector(SearchResultsViewController.onCloseButtonTapped(_:)), for: .touchUpInside)
        
        // Create title
        let titleSize = CGSize(width: self.view.bounds.width,
                               height: self.view.bounds.height * 0.1)
        let titleOrigin = CGPoint(x: (self.view.bounds.width / 2) - (titleSize.width / 2),
                                  y: (closeButton.frame.origin.y + closeButton.frame.size.height / 2) - (titleSize.height / 2))
        let title = UILabel(frame: CGRect(origin: titleOrigin, size: titleSize))
        title.textAlignment = .center
        title.font = title.font.withSize(22)
        title.text = "Search Results"
        self.view.addSubview(title)
        
        // Gallery
        let collectionViewLayout = UICollectionViewFlowLayout()
        
        let collectionViewSize = CGSize(
            width: self.view.bounds.width - (self.view.bounds.width * 0.05),
            height: self.view.bounds.height - (title.frame.maxY + self.view.bounds.height * 0.05))
        
        let collectionViewOrigin = CGPoint(
            x: (self.view.bounds.width / 2) - (collectionViewSize.width / 2),
            y: title.frame.maxY + 10)
        
        let collectionView = UICollectionView(
            frame: CGRect(origin: collectionViewOrigin,
                          size: collectionViewSize),
            collectionViewLayout: collectionViewLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.clear
        collectionView.register(PhotoViewCell.self, forCellWithReuseIdentifier: "PhotoViewCell")
        collectionView.autoresizingMask = UIView.AutoresizingMask(rawValue: UIView.AutoresizingMask.RawValue(UInt8(UIView.AutoresizingMask.flexibleWidth.rawValue) | UInt8(UIView.AutoresizingMask.flexibleHeight.rawValue)))
        
        self.view.addSubview(collectionView)
        self.collectionView = collectionView
        
        collectionView.reloadData()
        
        let objectDetectionImageView = ObjectDetectionImageView(frame: collectionView.frame)
        objectDetectionImageView.contentMode = .scaleAspectFit 
        objectDetectionImageView.clipsToBounds = true
        objectDetectionImageView.delegate = self
        self.view.addSubview(objectDetectionImageView)
        self.objectDetectionImageView = objectDetectionImageView
        self.objectDetectionImageView?.isHidden = true
    }
}

// MARK: - ObjectDetectionImageViewDelegate

extension SearchResultsViewController : ObjectDetectionImageViewDelegate{
    
    func onObjectDetectionImageViewDismissed(view:ObjectDetectionImageView){
        // remove effect
        guard let effectView = self.view.viewWithTag(99) else { return }
        effectView.removeFromSuperview()
    }
}

// MARK: - UICollectionViewDataSource & UICollectionViewDelegate

extension SearchResultsViewController : UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let searchResults = self.searchResults else{
            return 0
        }
        
        return searchResults.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoViewCell", for: indexPath) as! PhotoViewCell
        let idx = indexPath.row
        let searchResult = self.searchResults![idx]
        cell.searchResult = searchResult
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
        guard let cell = collectionView.cellForItem(at: indexPath) else{
            return
        }
        
        let cellFrame = cell.frame
        let cellOrigin = collectionView.convert(cell.frame.origin, to: collectionView.superview)
        
        let srcFrame = CGRect(origin: cellOrigin, size: cellFrame.size)
        let dstFrame = CGRect(origin: collectionView.frame.origin, size: collectionView.frame.size)
        
        let idx = indexPath.row
        let searchResult = self.searchResults![idx]
        
        let effect = UIBlurEffect(style: .regular)
        let visualEffectsView = UIVisualEffectView(effect: effect)
        visualEffectsView.tag = 99
        visualEffectsView.frame = self.view.bounds
        visualEffectsView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(visualEffectsView)
        
        self.view.bringSubviewToFront(self.objectDetectionImageView!)
        self.objectDetectionImageView?.show(searchResult:searchResult, from:srcFrame, to:dstFrame)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width
        
        return CGSize(width: width/4 - 1, height: width/4 - 1)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
}
