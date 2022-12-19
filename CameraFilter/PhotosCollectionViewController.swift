//
//  PhotosCollectionViewController.swift
//  CameraFilter
//
//  Created by Bibi on 2022/12/12.
//

import Foundation
import UIKit
import Photos
import RxSwift

class PhotosCollectionViewController: UICollectionViewController {
    
    private let selectedPhotoSubject = PublishSubject<UIImage>()
    var selectedPhoto: Observable<UIImage> {
        return selectedPhotoSubject.asObservable()
    }
    
    private var images = [PHAsset]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        populatePhotos()
    }
    
    private func populatePhotos() {
        // 포토라이브러리에 접근해 사진을 가져와 images에 넣고, 컬렉션뷰를 갱신한다
        PHPhotoLibrary.requestAuthorization(for: PHAccessLevel.readWrite) { [weak self] status in
            if status == .authorized { // = Allow all access to all photo
                let assets = PHAsset.fetchAssets(with: .image, options: nil)
                assets.enumerateObjects { assetObject, count, stop in
                    self?.images.append(assetObject)
                }
                
                self?.images.reverse()
                
                DispatchQueue.main.async {
                    self?.collectionView.reloadData()
                }
            }
        }
    }
    
    // override 메서드들은, collectionView.reloadData()호출 시 호출되는 메서드들이다.
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.images.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedAsset = self.images[indexPath.row]
        // PHAsset대신 UIImage가 필요하므로 매니저에게 요청
        PHImageManager.default().requestImage(for: selectedAsset, targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFit, options: nil) { [weak self] image, info in
            // image는 UIImage를, info는 image에 대한 정보를 알려준다.
            guard let info = info else { return }
            
            let isDegradedImage = info["PHImageResultIsDegradedKey"] as! Bool
            if !isDegradedImage { // 섬네일 이미지가 아닌 원본 이미지일때
                if let image = image {
                    self?.selectedPhotoSubject.onNext(image)// subject에 선택된 이미지를 전달
                    self?.dismiss(animated: true)
                }
            }
        }
        let viewController = ViewController()
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // 컬렉션뷰의 셀을 구성한다
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as? PhotoCollectionViewCell else {
            fatalError()
        }
        
        let asset = self.images[indexPath.row]
        
        let manager = PHImageManager.default()
        manager.requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFit, options: nil) { image, info in
            DispatchQueue.main.async {
                cell.photoImageView.image = image
            }
        }
        
        return cell
    }
}
