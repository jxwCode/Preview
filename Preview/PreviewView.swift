//
//  PreviewView.swift
//  CoreTextDemo
//
//  Created by jxw on 2019/8/8.
//  Copyright © 2019 jxw. All rights reserved.
//

import UIKit
import AVFoundation

class PreviewView: UIView {
    var images:[UIImage]! = [UIImage](){
        didSet{
            collectionView.reloadData()
        }
    }
    var currentIndex:Int = 0
    var isShowIndex = false
    private var _window:UIWindow?
    private var collectionView:UICollectionView!
    private var indexLabel:UILabel?
    
    init(isShowIndex:Bool) {
        super.init(frame: UIScreen.main.bounds)
        self.isShowIndex = isShowIndex
        self.backgroundColor = UIColor.yellow
        initContentView()
    }
    
    private func initContentView(){
        let screenBounds = UIScreen.main.bounds
        self.frame = screenBounds
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = screenBounds.size
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        
        collectionView = UICollectionView(frame: screenBounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.backgroundColor = .white
        collectionView.register(ZoomCell.classForCoder(), forCellWithReuseIdentifier: "ZoomCell")
        
        self.addSubview(collectionView)
        //是否展示索引
        if(isShowIndex){
            //X系列:top:44,bottom:34,非X系列:top:20,bottom:0
            let safeInset = UIApplication.shared.keyWindow?.safeAreaInsets
            let bottom = safeInset?.bottom ?? 0
            let top = safeInset?.top ?? 0
            let topInset = bottom > 0 ? top:0
            indexLabel = UILabel(frame: CGRect(x: 0, y: topInset, width: screenBounds.width, height: 40))
            indexLabel?.textAlignment = .center
            indexLabel?.textColor = .white
            indexLabel?.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
            self.addSubview(indexLabel!)
        }
    }
    
    func show(){
        collectionView.scrollToItem(at: IndexPath(row: currentIndex, section: 0), at: .centeredHorizontally, animated: false)
        updateIndex(index: currentIndex+1, total: images.count)

        _window = UIWindow(frame: self.bounds)
        _window?.windowLevel = .alert
        _window?.isHidden = false
        _window?.addSubview(self)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismiss(ges:)))
        _window?.addGestureRecognizer(tap)
        
        self.alpha = 0
        UIView.animate(withDuration: 0.8) {
            self.alpha = 1
        }
    }
    
    @objc func dismiss(ges:UIGestureRecognizer){
        UIView.animate(withDuration: 0.8) {
            self.alpha = 0
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.8) {
            self._window?.isHidden = true
            self._window = nil
        }
    }
    //更新索引
    func updateIndex(index:Int,total:Int){
        self.indexLabel?.text = "\(index)/\(total)"
    }
    
    deinit {
        print("deinit")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


extension PreviewView:UICollectionViewDelegate,UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ZoomCell", for: indexPath) as! ZoomCell
        cell.image = images![indexPath.row]
        return cell
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let point = self.convert(self.collectionView.center, to: self.collectionView)
        let indexPath = self.collectionView.indexPathForItem(at: point)!
        print(self.collectionView.center,indexPath,"self.collectionView.center")
        let count = images.count
        let row = indexPath.row
        if currentIndex != row{
            currentIndex = row
            self.updateIndex(index: row + 1, total: count)
        }
    }
    
}

class ZoomCell:UICollectionViewCell{
    private let minimumZoomScale: CGFloat = 1
    private var maximumZoomScale: CGFloat = 8
    private var scrollView:UIScrollView!
    private var imageView:UIImageView!
    var image:UIImage!{
        didSet{
            imageView.image = image
            imageView.isAccessibilityElement = image.isAccessibilityElement
            imageView.accessibilityLabel = image.accessibilityLabel
            imageView.accessibilityTraits = image.accessibilityTraits
            
            self.layoutIfNeeded()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initScrollView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initScrollView(){
        
        self.contentView.backgroundColor = .black
        
        imageView = UIImageView()
        
        scrollView = UIScrollView(frame: self.bounds)
        scrollView.decelerationRate = UIScrollView.DecelerationRate.fast
        scrollView.contentInset = UIEdgeInsets.zero
        scrollView.contentOffset = CGPoint.zero
        scrollView.isPagingEnabled = true
        scrollView.minimumZoomScale = minimumZoomScale
        scrollView.maximumZoomScale = max(maximumZoomScale, aspectFillZoomScale(forBoundingSize: self.contentView.frame.size, contentSize: self.imageView.frame.size))
        scrollView.delegate = self
        scrollView.addSubview(imageView)
        
        self.contentView.addSubview(scrollView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.image.size != CGSize.zero {
            let aspectFitItemSize = aspectFitSize(forContentOfSize: self.image.size, inBounds: self.scrollView.bounds.size)
            imageView.frame.size = aspectFitItemSize
            scrollView.contentSize = imageView.frame.size
            imageView.center = scrollView.center
        }
    }
}

extension ZoomCell:UIScrollViewDelegate{
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        imageView.center = contentCenter(forBoundingSize: scrollView.bounds.size, contentSize: scrollView.contentSize)
    }
}


// MARK: CalculteFunctions
extension ZoomCell{
    
    /// 计算size在某个rect下的同比例缩放得到的尺寸
    ///
    /// - Parameters:
    ///   - contentSize: 目标size
    ///   - bounds: 容器rect
    /// - Returns: 缩放后的size
    
    func aspectFitSize(forContentOfSize contentSize: CGSize, inBounds bounds: CGSize) -> CGSize {
        
        return AVMakeRect(aspectRatio: contentSize, insideRect: CGRect(origin: CGPoint.zero, size: bounds)).size
    }
    
    //获取缩放比例大小
    func aspectFillZoomScale(forBoundingSize boundingSize: CGSize, contentSize: CGSize) -> CGFloat {
        
        let aspectFitSize = aspectFitContentSize(forBoundingSize: boundingSize, contentSize: contentSize)
        
        return (floor(boundingSize.width) == floor(aspectFitSize.width)) ? (boundingSize.height / aspectFitSize.height): (boundingSize.width / aspectFitSize.width)
    }
    
    func aspectFitContentSize(forBoundingSize boundingSize: CGSize, contentSize: CGSize) -> CGSize {
        
        return AVMakeRect(aspectRatio: contentSize, insideRect: CGRect(origin: CGPoint.zero, size: boundingSize)).size
    }
    
    func contentCenter(forBoundingSize boundingSize: CGSize, contentSize: CGSize) -> CGPoint {
        
        let horizontalOffset = (boundingSize.width > contentSize.width) ? ((boundingSize.width - contentSize.width) * 0.5): 0.0
        let verticalOffset   = (boundingSize.height > contentSize.height) ? ((boundingSize.height - contentSize.height) * 0.5): 0.0
        
        return CGPoint(x: contentSize.width * 0.5 + horizontalOffset, y: contentSize.height * 0.5 + verticalOffset)
    }
    
}


