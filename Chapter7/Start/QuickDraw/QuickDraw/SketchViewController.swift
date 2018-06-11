//
//  SketchViewController.swift
//  QuickDraw
//
//  Created by Joshua Newnham on 27/12/2017.
//  Copyright © 2017 Method. All rights reserved.
//

import UIKit
import CoreVideo

class SketchViewController: UIViewController {
    
    enum SketchMode{
        case sketch, move, dispose
    }

    fileprivate let reuseIdentifier = "SketchPreviewCell"
    
    fileprivate let sectionInsets = UIEdgeInsets(top: 2.0, left: 2.0, bottom: 2.0, right: 2.0)
    
    // CollectionView to hold the suggested images that the user can tap to replace their current sketch
    @IBOutlet weak var collectionView: UICollectionView!
    
    // 'Instruction' label to indicate to the user the purpose of the CollectionView and it's contents
    // (should be hidden when no suggestions are available)
    @IBOutlet weak var toolBarLabel: UILabel!
    
    // Bespoke UIControl for managing the drawing and rendering of the sketches
    @IBOutlet weak var sketchView: SketchView!
    
    @IBOutlet weak var sketchModeButton: UIButton!
    
    @IBOutlet weak var moveModeButton: UIButton!
    
    @IBOutlet weak var disposeModeButton: UIButton!
    
    // Context is used to create CGImage's from CIImage's
    let ciContext = CIContext()
    
    // Facade encapsulating the process of managing
    // sketch classification and search
    let queryFacade = QueryFacade()
    
    // Current array of suggested images for substitution
    var queryImages = [UIImage]()
    
    // Used for 'moving' sketches
    var panRecognizer : UIPanGestureRecognizer!
    
    // Sketch currently being dragged 
    fileprivate var draggingSketch : Sketch?
    
    var mode : SketchMode = .sketch{
        didSet{
            onSketchModeChanged()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create and register the Pan Gesture Recognizer (used for the mode 'move')
        self.panRecognizer = UIPanGestureRecognizer(
            target: self,
            action: #selector(SketchViewController.onPanGestureRecognizer))
        
        // Assign the gesture to our main view
        self.view.gestureRecognizers = [panRecognizer]
        // Enable it (the pan gesture) only if the appropriate mode
        self.panRecognizer.isEnabled = self.mode == .move
        
        // Listen our for when the user finishes a stroke; after which we will
        // perform classification and a image search
        self.sketchView.addTarget(self, action: #selector(SketchViewController.onSketchViewEditingDidEnd), for: .editingDidEnd)
        
        // The QueryFacade communicates it's results via a deleate; here
        // we assign ourselves for handling the results
        queryFacade.delegate = self 
    }
}

// MARK: - Editing actions from the SketchView

extension SketchViewController{
    
    /**
     Target method for handling editing changes (triggered when editing has ended) via the SketchView;
     When called; get reference to the current sketch and pass it to the QueryFacade to handle the
     prediction and lookup.
     */
    @objc func onSketchViewEditingDidEnd(_ sender:SketchView){
        
    }
}

// MARK: - UICollectionViewDelegate

extension SketchViewController : UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath)
    {
        
    }
}

// MARK: - QueryDelegate

extension SketchViewController : QueryDelegate{
    
    func onQueryCompleted(status: Int, result:QueryResult?){
        
    }
    
}

// MARK: - UICollectionViewDataSource

extension SketchViewController : UICollectionViewDataSource{
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return queryImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: reuseIdentifier,
            for: indexPath) as! SketchPreviewCell
        
        cell.imageView.image = queryImages[indexPath.row]
        
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension SketchViewController : UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let paddingSpace = sectionInsets.top + sectionInsets.bottom
        let cellDim = collectionView.frame.height - paddingSpace
        
        return CGSize(width: cellDim, height: cellDim)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

// MARK: - Interface Builder Actions (Mode)

extension SketchViewController{
    
    @IBAction func onPenTapped(_ sender: Any) {
        self.mode = .sketch
    }
    
    @IBAction func onMoveTapped(_ sender: Any) {
        self.mode = .move
    }
    
    @IBAction func onDisposeTapped(_ sender: Any) {
        self.mode = .dispose
    }
}

// MARK: Property callback (Mode) 

extension SketchViewController{
    
    /**
     Called whent he mode property has been set; responsible for updating the mode and UI
     */
    fileprivate func onSketchModeChanged(){
        // update UI
        self.sketchModeButton.isSelected = self.mode == .sketch
        self.moveModeButton.isSelected = self.mode == .move
        self.disposeModeButton.isSelected = self.mode == .dispose
        
        // enable/disable user interaction for sketchView
        self.sketchView.isEnabled = self.mode == .sketch
        
        // enable/disable gesture recognizer used for dragging sketches
        self.panRecognizer.isEnabled = self.mode == .move
        
        if self.mode == SketchMode.dispose{
            // remove any suggested images
            self.queryImages.removeAll()
            self.collectionView.reloadData()
            self.toolBarLabel.isHidden = queryImages.count == 0
            
            // remove all sketches from sketchview
            self.sketchView.removeAllSketches()
            
            // switch back to the default mode (sketch)
            self.mode = .sketch
        }
    }
}

// MARK: - UIPanGestureRecognizer

extension SketchViewController{
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else{
            return
        }
        
        let touchPoint = touch.location(in: self.sketchView)
        
        self.draggingSketch = nil
        
        // Find first sketch that contain this point within it's boundingbox
        for sketch in self.sketchView.sketches.reversed(){
            if sketch.boundingBox.contains(touchPoint){
                self.draggingSketch = sketch
                break
            }
        }
    }
    
    @objc func onPanGestureRecognizer(gestureRecognizer:UIPanGestureRecognizer){
        guard let draggingSketch = self.draggingSketch else{ return }
        
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            let translation = gestureRecognizer.translation(in: self.sketchView)
            
            // update the sketches center based on the touch translation
            var center = draggingSketch.center
            center.x += translation.x
            center.y += translation.y
            draggingSketch.center = center
            
            gestureRecognizer.setTranslation(CGPoint.zero, in: self.sketchView)
            
            // request the sketchView to redraw itself
            self.sketchView.setNeedsDisplay()
            
        } else if gestureRecognizer.state == .ended || gestureRecognizer.state == .cancelled{
            self.draggingSketch = nil
        }
    }
    
}
