//
//  ViewController.swift
//  ObjectDetection
//
//  Created by Joshua Newnham on 13/05/2018.
//  Copyright © 2018 Joshua Newnham. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {

    var searchInputView : SearchInputView?
    
    var iconImages = [(image:UIImage, selectedImage:UIImage)]()
    
    var iconButtonSize : CGSize?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initUI()
    }

}

// MARK: - UI Actions

extension SearchViewController{
    
    @objc func onSearchButtonTapped(_ sender:UIButton){
        guard let searchInputView = self.searchInputView, searchInputView.searchBoxes.count > 0 else{ return }
        
        let searchResultsVC = SearchResultsViewController()
        searchResultsVC.view.backgroundColor = UIColor.white
        searchResultsVC.modalPresentationStyle = .fullScreen
        searchResultsVC.searchCriteria = searchInputView.normalisedSearchBoxes
        
        present(searchResultsVC, animated: true) {
            searchResultsVC.startSearch()
        }
    }
    
    @objc func onUndoButtonTapped(_ sender:UIButton){
        self.searchInputView?.undo()
    }
}

// MARK: - User Interface

extension SearchViewController{
    
    func initUI(){
        
        // Collection view for object selection
        for i in 0..<DetectableObject.objects.count{
            let imageSrc = DetectableObject.objects[i].label
            let selectedImageSrc = "\(DetectableObject.objects[i].label)_selected"
            
            guard let image = UIImage(named: imageSrc),
                let selectedImage = UIImage(named:selectedImageSrc) else{
                fatalError("\(imageSrc) is not available")
            }
            
            self.iconImages.append((
                image: image,
                selectedImage: selectedImage))
            
            if iconButtonSize == nil{
                iconButtonSize = CGSize(width: self.view.bounds.width * 0.2,
                                        height: self.view.bounds.width * 0.2 * (image.size.height/image.size.width))
            }
        }
        
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .horizontal
        collectionViewLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionViewLayout.itemSize = CGSize(width: iconButtonSize!.width,
                                               height: iconButtonSize!.height)
        collectionViewLayout.minimumLineSpacing = 0
        collectionViewLayout.minimumInteritemSpacing = 0
        let collectionView = UICollectionView(frame: CGRect(x: 0,
                                                            y: self.view.bounds.height-iconButtonSize!.height,
                                                            width: self.view.bounds.width,
                                                            height: iconButtonSize!.height),
                                              collectionViewLayout: collectionViewLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.clear
        collectionView.register(IconViewCell.self, forCellWithReuseIdentifier: "IconViewCell")
        self.view.addSubview(collectionView)
        collectionView.reloadData()
                
        // Create SearchInputView
        let searchViewSize = CGSize(width: self.view.bounds.width - (self.view.bounds.width * 0.05),
                                    height: self.view.bounds.width - (self.view.bounds.width * 0.05))
        let searchViewOrigin = CGPoint(x: (self.view.bounds.width / 2) - (searchViewSize.width / 2),
                                       y: (self.view.bounds.height / 2) - (searchViewSize.height / 2))
        
        let searchInputView = SearchInputView(frame: CGRect(
            origin: searchViewOrigin,
            size: searchViewSize))
        self.view.addSubview(searchInputView)
            
        searchInputView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        searchInputView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0).isActive = true
        
        self.searchInputView = searchInputView
        
        // Create search button
        let searchButtonImage = UIImage(named: "search")
        let searchDownButtonImage = UIImage(named: "search_down")
        let searchButtonSize = CGSize(
            width: self.view.bounds.width * 0.08,
            height: self.view.bounds.width * 0.08 * (searchButtonImage!.size.height / searchButtonImage!.size.width))
        let searchButton = UIButton(
            frame:CGRect(
                x: self.view.bounds.width - (searchButtonSize.width * 1.3),
                y: UIApplication.shared.statusBarFrame.height + 10,
                width: searchButtonSize.width,
                height: searchButtonSize.height))
        self.view.addSubview(searchButton)
        searchButton.setImage(searchButtonImage, for: .normal)
        searchButton.setImage(searchDownButtonImage, for: .highlighted)
        searchButton.addTarget(
            self,
            action: #selector(SearchViewController.onSearchButtonTapped(_:)), for: .touchUpInside)
        
        // Create undo button
        let undoButtonImage = UIImage(named: "undo")
        let undoDownButtonImage = UIImage(named: "undo_down")
        let undoButtonSize = CGSize(
            width: self.view.bounds.width * 0.08,
            height: self.view.bounds.width * 0.08 * (undoButtonImage!.size.height / undoButtonImage!.size.width))
        let undoButton = UIButton(
            frame:CGRect(
                x: (undoButtonSize.width * 0.3),
                y: UIApplication.shared.statusBarFrame.height + 10,
                width: undoButtonSize.width,
                height: undoButtonSize.height))
        self.view.addSubview(undoButton)
        undoButton.setImage(undoButtonImage, for: .normal)
        undoButton.setImage(undoDownButtonImage, for: .highlighted)
        undoButton.addTarget(
            self,
            action: #selector(SearchViewController.onUndoButtonTapped(_:)), for: .touchUpInside)
        
        // Create title
        let titleSize = CGSize(width: self.view.bounds.width,
                               height: self.view.bounds.height * 0.1)
        let titleOrigin = CGPoint(x: (self.view.bounds.width / 2) - (titleSize.width / 2),
                                  y: (searchButton.frame.origin.y + searchButton.frame.size.height / 2) - (titleSize.height / 2))
        let title = UILabel(frame: CGRect(origin: titleOrigin, size: titleSize))
        title.textAlignment = .center
        title.font = title.font.withSize(22)
        title.text = "Visual Search"
        self.view.addSubview(title)
        
    }
}

// MARK: - UICollectionViewDataSource & UICollectionViewDelegate

extension SearchViewController : UICollectionViewDataSource, UICollectionViewDelegate{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return DetectableObject.objects.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "IconViewCell", for: indexPath) as! IconViewCell
        let idx = indexPath.row
        cell.image = self.iconImages[idx].image
        cell.selectedImage = self.iconImages[idx].selectedImage
        cell.index = idx
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool{
        let cell = collectionView.cellForItem(at: indexPath) as! IconViewCell
        return !cell.isSelected
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
        let idx = indexPath.row
        self.searchInputView?.selectedDetectableObject = DetectableObject.objects[idx]
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath){
        self.searchInputView?.selectedDetectableObject = nil
    }
}


