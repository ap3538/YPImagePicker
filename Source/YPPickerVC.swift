//
//  YYPPickerVC.swift
//  YPPickerVC
//
//  Created by Sacha Durand Saint Omer on 25/10/16.
//  Copyright © 2016 Yummypets. All rights reserved.
//

//import UIKit
//import Stevia
//import Photos
//
//protocol YPPickerVCDelegate: AnyObject {
//    func libraryHasNoItems()
//    func shouldAddToSelection(indexPath: IndexPath, numSelections: Int) -> Bool
//}
//
//open class YPPickerVC: YPBottomPager, YPBottomPagerDelegate {
//
//    let albumsManager = YPAlbumsManager()
//    var shouldHideStatusBar = false
//    var initialStatusBarHidden = false
//    weak var pickerVCDelegate: YPPickerVCDelegate?
//
//    override open var prefersStatusBarHidden: Bool {
//        return (shouldHideStatusBar || initialStatusBarHidden) && YPConfig.hidesStatusBar
//    }
//
//    /// Private callbacks to YPImagePicker
//    public var didClose:(() -> Void)?
//    public var didSelectItems: (([YPMediaItem]) -> Void)?
//
//    enum Mode {
//        case library
//        case camera
//        case video
//    }
//
//    private var libraryVC: YPLibraryVC?
//    private var cameraVC: YPCameraVC?
//    private var videoVC: YPVideoCaptureVC?
//
//    var mode = Mode.camera
//
//    var capturedImage: UIImage?
//
//    open override func viewDidLoad() {
//        super.viewDidLoad()
//
//        view.backgroundColor = YPConfig.colors.safeAreaBackgroundColor
//
//        delegate = self
//
//        // Force Library only when using `minNumberOfItems`.
//        if YPConfig.library.minNumberOfItems > 1 {
//            YPImagePickerConfiguration.shared.screens = [.library]
//        }
//
//        // Library
//        if YPConfig.screens.contains(.library) {
//            libraryVC = YPLibraryVC()
//            libraryVC?.delegate = self
//        }
//
//        // Camera
//        if YPConfig.screens.contains(.photo) {
//            cameraVC = YPCameraVC()
//            cameraVC?.didCapturePhoto = { [weak self] img in
//                self?.didSelectItems?([YPMediaItem.photo(p: YPMediaPhoto(image: img,
//                                                                         fromCamera: true))])
//            }
//        }
//
//        // Video
//        if YPConfig.screens.contains(.video) {
//            videoVC = YPVideoCaptureVC()
//            videoVC?.didCaptureVideo = { [weak self] videoURL in
//                self?.didSelectItems?([YPMediaItem
//                                        .video(v: YPMediaVideo(thumbnail: thumbnailFromVideoPath(videoURL),
//                                                               videoURL: videoURL,
//                                                               fromCamera: true))])
//            }
//        }
//
//        // Show screens
//        var vcs = [UIViewController]()
//        for screen in YPConfig.screens {
//            switch screen {
//            case .library:
//                if let libraryVC = libraryVC {
//                    vcs.append(libraryVC)
//                }
//            case .photo:
//                if let cameraVC = cameraVC {
//                    vcs.append(cameraVC)
//                }
//            case .video:
//                if let videoVC = videoVC {
//                    vcs.append(videoVC)
//                }
//            }
//        }
//        controllers = vcs
//
//        // Select good mode
//        if YPConfig.screens.contains(YPConfig.startOnScreen) {
//            switch YPConfig.startOnScreen {
//            case .library:
//                mode = .library
//            case .photo:
//                mode = .camera
//            case .video:
//                mode = .video
//            }
//        }
//
//        // Select good screen
//        if let index = YPConfig.screens.firstIndex(of: YPConfig.startOnScreen) {
//            startOnPage(index)
//        }
//
//        YPHelper.changeBackButtonIcon(self)
//        YPHelper.changeBackButtonTitle(self)
//    }
//
//    open override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        cameraVC?.v.shotButton.isEnabled = true
//
//        updateMode(with: currentController)
//    }
//
//    open override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        shouldHideStatusBar = true
//        initialStatusBarHidden = true
//        UIView.animate(withDuration: 0.3) {
//            self.setNeedsStatusBarAppearanceUpdate()
//        }
//    }
//
//    internal func pagerScrollViewDidScroll(_ scrollView: UIScrollView) { }
//
//    func modeFor(vc: UIViewController) -> Mode {
//        switch vc {
//        case is YPLibraryVC:
//            return .library
//        case is YPCameraVC:
//            return .camera
//        case is YPVideoCaptureVC:
//            return .video
//        default:
//            return .camera
//        }
//    }
//
//    func pagerDidSelectController(_ vc: UIViewController) {
//        updateMode(with: vc)
//    }
//
//    func updateMode(with vc: UIViewController) {
//        stopCurrentCamera()
//
//        // Set new mode
//        mode = modeFor(vc: vc)
//
//        // Re-trigger permission check
//        if let vc = vc as? YPLibraryVC {
//            vc.doAfterLibraryPermissionCheck { [weak vc] in
//                vc?.initialize()
//            }
//        } else if let cameraVC = vc as? YPCameraVC {
//            cameraVC.start()
//        } else if let videoVC = vc as? YPVideoCaptureVC {
//            videoVC.start()
//        }
//
//        updateUI()
//    }
//
//    func stopCurrentCamera() {
//        switch mode {
//        case .library:
//            libraryVC?.pausePlayer()
//        case .camera:
//            cameraVC?.stopCamera()
//        case .video:
//            videoVC?.stopCamera()
//        }
//    }
//
//    open override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        shouldHideStatusBar = false
//    }
//
//    deinit {
//        stopAll()
//        ypLog("YPPickerVC deinited ✅")
//    }
//
//    @objc
//    func navBarTapped() {
//        guard !(libraryVC?.isProcessing ?? false) else {
//            return
//        }
//
//        let vc = YPAlbumVC(albumsManager: albumsManager)
//        let navVC = UINavigationController(rootViewController: vc)
//        navVC.navigationBar.tintColor = .ypLabel
//
//        vc.didSelectAlbum = { [weak self] album in
//            self?.libraryVC?.setAlbum(album)
//            self?.setTitleViewWithTitle(aTitle: album.title)
//            navVC.dismiss(animated: true, completion: nil)
//        }
//        present(navVC, animated: true, completion: nil)
//    }
//
//    func setTitleViewWithTitle(aTitle: String) {
//        let titleView = UIView()
//        titleView.frame = CGRect(x: 0, y: 0, width: 200, height: 40)
//
//        let label = UILabel()
//        label.text = aTitle
//        // Use YPConfig font
//        label.font = YPConfig.fonts.pickerTitleFont
//
//        // Use custom textColor if set by user.
//        if let navBarTitleColor = UINavigationBar.appearance().titleTextAttributes?[.foregroundColor] as? UIColor {
//            label.textColor = navBarTitleColor
//        }
//
//        if YPConfig.library.options != nil {
//            titleView.subviews(
//                label
//            )
//            |-(>=8)-label.centerHorizontally()-(>=8)-|
//            align(horizontally: label)
//        } else {
//            let arrow = UIImageView()
//            arrow.image = YPConfig.icons.arrowDownIcon
//            arrow.image = arrow.image?.withRenderingMode(.alwaysTemplate)
//            arrow.tintColor = .ypLabel
//
//            let attributes = UINavigationBar.appearance().titleTextAttributes
//            if let attributes = attributes, let foregroundColor = attributes[.foregroundColor] as? UIColor {
//                arrow.image = arrow.image?.withRenderingMode(.alwaysTemplate)
//                arrow.tintColor = foregroundColor
//            }
//
//            let button = UIButton()
//            button.addTarget(self, action: #selector(navBarTapped), for: .touchUpInside)
//            button.setBackgroundColor(UIColor.white.withAlphaComponent(0.5), forState: .highlighted)
//
//            titleView.subviews(
//                label,
//                arrow,
//                button
//            )
//            button.fillContainer()
//            |-(>=8)-label.centerHorizontally()-arrow-(>=8)-|
//            align(horizontally: label-arrow)
//        }
//
//        label.firstBaselineAnchor.constraint(equalTo: titleView.bottomAnchor, constant: -14).isActive = true
//
//        titleView.heightAnchor.constraint(equalToConstant: 40).isActive = true
//        navigationItem.titleView = titleView
//    }
//
//    func updateUI() {
//        if !YPConfig.hidesCancelButton {
//            // Update Nav Bar state.
//            navigationItem.leftBarButtonItem = UIBarButtonItem(title: YPConfig.wordings.cancel,
//                                                               style: .plain,
//                                                               target: self,
//                                                               action: #selector(close))
//        }
//        switch mode {
//        case .library:
//            setTitleViewWithTitle(aTitle: libraryVC?.title ?? "")
//            navigationItem.rightBarButtonItem = UIBarButtonItem(title: YPConfig.wordings.next,
//                                                                style: .done,
//                                                                target: self,
//                                                                action: #selector(done))
//            navigationItem.rightBarButtonItem?.tintColor = YPConfig.colors.tintColor
//
//            // Disable Next Button until minNumberOfItems is reached.
//            navigationItem.rightBarButtonItem?.isEnabled =
//                libraryVC!.selectedItems.count >= YPConfig.library.minNumberOfItems
//
//        case .camera:
//            navigationItem.titleView = nil
//            title = cameraVC?.title
//            navigationItem.rightBarButtonItem = nil
//        case .video:
//            navigationItem.titleView = nil
//            title = videoVC?.title
//            navigationItem.rightBarButtonItem = nil
//        }
//
//        navigationItem.rightBarButtonItem?.setFont(font: YPConfig.fonts.rightBarButtonFont, forState: .normal)
//        navigationItem.rightBarButtonItem?.setFont(font: YPConfig.fonts.rightBarButtonFont, forState: .disabled)
//        navigationItem.leftBarButtonItem?.setFont(font: YPConfig.fonts.leftBarButtonFont, forState: .normal)
//    }
//
//    @objc
//    func close() {
//        // Cancelling exporting of all videos
//        if let libraryVC = libraryVC {
//            libraryVC.mediaManager.forseCancelExporting()
//        }
//        self.didClose?()
//    }
//
//    // When pressing "Next"
//    @objc
//    func done() {
//        guard let libraryVC = libraryVC else { ypLog("YPLibraryVC deallocated"); return }
//
//        if mode == .library {
//            libraryVC.selectedMedia(photoCallback: { photo in
//                self.didSelectItems?([YPMediaItem.photo(p: photo)])
//            }, videoCallback: { video in
//                self.didSelectItems?([YPMediaItem
//                                        .video(v: video)])
//            }, multipleItemsCallback: { items in
//                self.didSelectItems?(items)
//            })
//        }
//    }
//
//    func stopAll() {
//        libraryVC?.v.assetZoomableView.videoView.deallocate()
//        videoVC?.stopCamera()
//        cameraVC?.stopCamera()
//    }
//}
//
//extension YPPickerVC: YPLibraryViewDelegate {
//
//    public func libraryViewDidTapNext() {
//        libraryVC?.isProcessing = true
//        DispatchQueue.main.async {
//            self.v.scrollView.isScrollEnabled = false
//            self.libraryVC?.v.fadeInLoader()
//            self.navigationItem.rightBarButtonItem = YPLoaders.defaultLoader
//        }
//    }
//
//    public func libraryViewStartedLoadingImage() {
//        // TODO remove to enable changing selection while loading but needs cancelling previous image requests.
//        libraryVC?.isProcessing = true
//        DispatchQueue.main.async {
//            self.libraryVC?.v.fadeInLoader()
//        }
//    }
//
//    public func libraryViewFinishedLoading() {
//        libraryVC?.isProcessing = false
//        DispatchQueue.main.async {
//            self.v.scrollView.isScrollEnabled = YPConfig.isScrollToChangeModesEnabled
//            self.libraryVC?.v.hideLoader()
//            self.updateUI()
//        }
//    }
//
//    public func libraryViewDidToggleMultipleSelection(enabled: Bool) {
//        var offset = v.header.frame.height
//        if #available(iOS 11.0, *) {
//            offset += v.safeAreaInsets.bottom
//        }
//
//        v.header.bottomConstraint?.constant = enabled ? offset : 0
//        v.layoutIfNeeded()
//        updateUI()
//    }
//
//    public func libraryViewHaveNoItems() {
//        pickerVCDelegate?.libraryHasNoItems()
//    }
//
//    public func libraryViewShouldAddToSelection(indexPath: IndexPath, numSelections: Int) -> Bool {
//        return pickerVCDelegate?.shouldAddToSelection(indexPath: indexPath, numSelections: numSelections) ?? true
//    }
//}

//Code2 Added Manage button and ActionSheet

//import UIKit
//import Stevia
//import Photos
//
//protocol YPPickerVCDelegate: AnyObject {
//    func libraryHasNoItems()
//    func shouldAddToSelection(indexPath: IndexPath, numSelections: Int) -> Bool
//}
//
//open class YPPickerVC: YPBottomPager, YPBottomPagerDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
//
//    let albumsManager = YPAlbumsManager()
//    var shouldHideStatusBar = false
//    var initialStatusBarHidden = false
//    weak var pickerVCDelegate: YPPickerVCDelegate?
//
//    override open var prefersStatusBarHidden: Bool {
//        return (shouldHideStatusBar || initialStatusBarHidden) && YPConfig.hidesStatusBar
//    }
//
//    /// Private callbacks to YPImagePicker
//    public var didClose:(() -> Void)?
//    public var didSelectItems: (([YPMediaItem]) -> Void)?
//
//    enum Mode {
//        case library
//        case camera
//        case video
//    }
//
//    private var libraryVC: YPLibraryVC?
//    private var cameraVC: YPCameraVC?
//    private var videoVC: YPVideoCaptureVC?
//
//    var mode = Mode.camera
//
//    var capturedImage: UIImage?
//
//    open override func viewDidLoad() {
//        super.viewDidLoad()
//
//        view.backgroundColor = YPConfig.colors.safeAreaBackgroundColor
//
//        delegate = self
//
//        // Force Library only when using `minNumberOfItems`.
//        if YPConfig.library.minNumberOfItems > 1 {
//            YPImagePickerConfiguration.shared.screens = [.library]
//        }
//
//        // Library
//        if YPConfig.screens.contains(.library) {
//            libraryVC = YPLibraryVC()
//            libraryVC?.delegate = self
//        }
//
//        // Camera
//        if YPConfig.screens.contains(.photo) {
//            cameraVC = YPCameraVC()
//            cameraVC?.didCapturePhoto = { [weak self] img in
//                self?.didSelectItems?([YPMediaItem.photo(p: YPMediaPhoto(image: img,
//                                                                         fromCamera: true))])
//            }
//        }
//
//        // Video
//        if YPConfig.screens.contains(.video) {
//            videoVC = YPVideoCaptureVC()
//            videoVC?.didCaptureVideo = { [weak self] videoURL in
//                self?.didSelectItems?([YPMediaItem
//                                        .video(v: YPMediaVideo(thumbnail: thumbnailFromVideoPath(videoURL),
//                                                               videoURL: videoURL,
//                                                               fromCamera: true))])
//            }
//        }
//
//        // Show screens
//        var vcs = [UIViewController]()
//        for screen in YPConfig.screens {
//            switch screen {
//            case .library:
//                if let libraryVC = libraryVC {
//                    vcs.append(libraryVC)
//                }
//            case .photo:
//                if let cameraVC = cameraVC {
//                    vcs.append(cameraVC)
//                }
//            case .video:
//                if let videoVC = videoVC {
//                    vcs.append(videoVC)
//                }
//            }
//        }
//        controllers = vcs
//
//        // Select good mode
//        if YPConfig.screens.contains(YPConfig.startOnScreen) {
//            switch YPConfig.startOnScreen {
//            case .library:
//                mode = .library
//            case .photo:
//                mode = .camera
//            case .video:
//                mode = .video
//            }
//        }
//
//        // Select good screen
//        if let index = YPConfig.screens.firstIndex(of: YPConfig.startOnScreen) {
//            startOnPage(index)
//        }
//
//        YPHelper.changeBackButtonIcon(self)
//        YPHelper.changeBackButtonTitle(self)
//    }
//
//    open override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        cameraVC?.v.shotButton.isEnabled = true
//
//        updateMode(with: currentController)
//    }
//
//    open override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        shouldHideStatusBar = true
//        initialStatusBarHidden = true
//        UIView.animate(withDuration: 0.3) {
//            self.setNeedsStatusBarAppearanceUpdate()
//        }
//    }
//
//
//    internal func pagerScrollViewDidScroll(_ scrollView: UIScrollView) { }
//
//    func modeFor(vc: UIViewController) -> Mode {
//        switch vc {
//        case is YPLibraryVC:
//            return .library
//        case is YPCameraVC:
//            return .camera
//        case is YPVideoCaptureVC:
//            return .video
//        default:
//            return .camera
//        }
//    }
//
//    func pagerDidSelectController(_ vc: UIViewController) {
//        updateMode(with: vc)
//    }
//
//    func updateMode(with vc: UIViewController) {
//        stopCurrentCamera()
//
//        // Set new mode
//        mode = modeFor(vc: vc)
//
//        // Re-trigger permission check
//        if let vc = vc as? YPLibraryVC {
//            vc.doAfterLibraryPermissionCheck { [weak vc] in
//                vc?.initialize()
//            }
//        } else if let cameraVC = vc as? YPCameraVC {
//            cameraVC.start()
//        } else if let videoVC = vc as? YPVideoCaptureVC {
//            videoVC.start()
//        }
//
//        updateUI()
//    }
//
//    func stopCurrentCamera() {
//        switch mode {
//        case .library:
//            libraryVC?.pausePlayer()
//        case .camera:
//            cameraVC?.stopCamera()
//        case .video:
//            videoVC?.stopCamera()
//        }
//    }
//
//    open override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        shouldHideStatusBar = false
//    }
//
//    deinit {
//        stopAll()
//        ypLog("YPPickerVC deinited ✅")
//    }
//
//    @objc
//    func navBarTapped() {
//        guard !(libraryVC?.isProcessing ?? false) else {
//            return
//        }
//
//        let vc = YPAlbumVC(albumsManager: albumsManager)
//        let navVC = UINavigationController(rootViewController: vc)
//        navVC.navigationBar.tintColor = .ypLabel
//
//        vc.didSelectAlbum = { [weak self] album in
//            self?.libraryVC?.setAlbum(album)
//            self?.setTitleViewWithTitle(aTitle: album.title)
//            navVC.dismiss(animated: true, completion: nil)
//        }
//        present(navVC, animated: true, completion: nil)
//    }
//
//    func setTitleViewWithTitle(aTitle: String) {
//        let titleView = UIView()
//        titleView.frame = CGRect(x: 0, y: 0, width: 200, height: 40)
//
//        let label = UILabel()
//        label.text = aTitle
//        // Use YPConfig font
//        label.font = YPConfig.fonts.pickerTitleFont
//
//        // Use custom textColor if set by user.
//        if let navBarTitleColor = UINavigationBar.appearance().titleTextAttributes?[.foregroundColor] as? UIColor {
//            label.textColor = navBarTitleColor
//        }
//
//        if YPConfig.library.options != nil {
//            titleView.subviews(
//                label
//            )
//            |-(>=8)-label.centerHorizontally()-(>=8)-|
//            align(horizontally: label)
//        } else {
//            let arrow = UIImageView()
//            arrow.image = YPConfig.icons.arrowDownIcon
//            arrow.image = arrow.image?.withRenderingMode(.alwaysTemplate)
//            arrow.tintColor = .ypLabel
//
//            let attributes = UINavigationBar.appearance().titleTextAttributes
//            if let attributes = attributes, let foregroundColor = attributes[.foregroundColor] as? UIColor {
//                arrow.image = arrow.image?.withRenderingMode(.alwaysTemplate)
//                arrow.tintColor = foregroundColor
//            }
//
//            let button = UIButton()
//            button.addTarget(self, action: #selector(navBarTapped), for: .touchUpInside)
//            button.setBackgroundColor(UIColor.white.withAlphaComponent(0.5), forState: .highlighted)
//
//            titleView.subviews(
//                label,
//                arrow,
//                button
//            )
//            button.fillContainer()
//            |-(>=8)-label.centerHorizontally()-arrow-(>=8)-|
//            align(horizontally: label-arrow)
//        }
//
//        label.firstBaselineAnchor.constraint(equalTo: titleView.bottomAnchor, constant: -14).isActive = true
//
//        titleView.heightAnchor.constraint(equalToConstant: 40).isActive = true
//        navigationItem.titleView = titleView
//    }
//
//    func updateUI() {
//        if !YPConfig.hidesCancelButton {
//            // Update Nav Bar state.
//            let cancelButton = UIBarButtonItem(title: YPConfig.wordings.cancel,
//                                               style: .plain,
//                                               target: self,
//                                               action: #selector(close))
//            let manageButton = UIBarButtonItem(title: "Manage",
//                                               style: .plain,
//                                               target: self,
//                                               action: #selector(manageButtonTapped)) // Please make sure to call the correct selector here
//            navigationItem.leftBarButtonItems = [cancelButton, manageButton]
//        }
//        switch mode {
//        case .library:
//            setTitleViewWithTitle(aTitle: libraryVC?.title ?? "")
//            navigationItem.rightBarButtonItem = UIBarButtonItem(title: YPConfig.wordings.next,
//                                                                style: .done,
//                                                                target: self,
//                                                                action: #selector(done))
//            navigationItem.rightBarButtonItem?.tintColor = YPConfig.colors.tintColor
//
//            // Disable Next Button until minNumberOfItems is reached.
//            navigationItem.rightBarButtonItem?.isEnabled =
//                libraryVC!.selectedItems.count >= YPConfig.library.minNumberOfItems
//
//        case .camera:
//            navigationItem.titleView = nil
//            title = cameraVC?.title
//            navigationItem.rightBarButtonItem = nil
//        case .video:
//            navigationItem.titleView = nil
//            title = videoVC?.title
//            navigationItem.rightBarButtonItem = nil
//        }
//
//        navigationItem.rightBarButtonItem?.setFont(font: YPConfig.fonts.rightBarButtonFont, forState: .normal)
//        navigationItem.rightBarButtonItem?.setFont(font: YPConfig.fonts.rightBarButtonFont, forState: .disabled)
//        navigationItem.leftBarButtonItem?.setFont(font: YPConfig.fonts.leftBarButtonFont, forState: .normal)
//    }
//
//    // MARK: - Actions
//
//    @objc func manageButtonTapped() {
//        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//
//        print("Manage button tapped")
//
//        // Select More Photos action
//        let selectMorePhotosAction = UIAlertAction(title: "Select More Photos", style: .default) { _ in
//            let imagePickerController = UIImagePickerController()
//            imagePickerController.sourceType = .photoLibrary
//            imagePickerController.delegate = self
//            self.present(imagePickerController, animated: true, completion: nil)
//        }
//
//
//        // Change Settings action
//        let changeSettingsAction = UIAlertAction(title: "Change Settings", style: .default) { _ in
//            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
//                UIApplication.shared.open(settingsURL)
//            }
//        }
//
//        // Cancel action
//        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
//
//        if let popoverController = actionSheet.popoverPresentationController {
//            popoverController.sourceView = self.view
//            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
//            popoverController.permittedArrowDirections = []
//        }
//
//        // Add actions to the actionSheet
//        actionSheet.addAction(selectMorePhotosAction)
//        actionSheet.addAction(changeSettingsAction)
//        actionSheet.addAction(cancelAction)
//
//        // Present action sheet
//        self.present(actionSheet, animated: true, completion: nil)
//    }
//
//
//
//
//
//    @objc
//    func close() {
//        // Cancelling exporting of all videos
//        if let libraryVC = libraryVC {
//            libraryVC.mediaManager.forseCancelExporting()
//        }
//        self.didClose?()
//    }
//
//    // When pressing "Next"
//    @objc
//    func done() {
//        guard let libraryVC = libraryVC else { ypLog("YPLibraryVC deallocated"); return }
//
//        if mode == .library {
//            libraryVC.selectedMedia(photoCallback: { photo in
//                self.didSelectItems?([YPMediaItem.photo(p: photo)])
//            }, videoCallback: { video in
//                self.didSelectItems?([YPMediaItem
//                                        .video(v: video)])
//            }, multipleItemsCallback: { items in
//                self.didSelectItems?(items)
//            })
//        }
//    }
//
//    func stopAll() {
//        libraryVC?.v.assetZoomableView.videoView.deallocate()
//        videoVC?.stopCamera()
//        cameraVC?.stopCamera()
//    }
//}
//
//extension YPPickerVC: YPLibraryViewDelegate {
//
//    public func libraryViewDidTapNext() {
//        libraryVC?.isProcessing = true
//        DispatchQueue.main.async {
//            self.v.scrollView.isScrollEnabled = false
//            self.libraryVC?.v.fadeInLoader()
//            self.navigationItem.rightBarButtonItem = YPLoaders.defaultLoader
//        }
//    }
//
//    public func libraryViewStartedLoadingImage() {
//        // TODO remove to enable changing selection while loading but needs cancelling previous image requests.
//        libraryVC?.isProcessing = true
//        DispatchQueue.main.async {
//            self.libraryVC?.v.fadeInLoader()
//        }
//    }
//
//    public func libraryViewFinishedLoading() {
//        libraryVC?.isProcessing = false
//        DispatchQueue.main.async {
//            self.v.scrollView.isScrollEnabled = YPConfig.isScrollToChangeModesEnabled
//            self.libraryVC?.v.hideLoader()
//            self.updateUI()
//        }
//    }
//
//    public func libraryViewDidToggleMultipleSelection(enabled: Bool) {
//        var offset = v.header.frame.height
//        if #available(iOS 11.0, *) {
//            offset += v.safeAreaInsets.bottom
//        }
//
//        v.header.bottomConstraint?.constant = enabled ? offset : 0
//        v.layoutIfNeeded()
//        updateUI()
//    }
//
//    public func libraryViewHaveNoItems() {
//        pickerVCDelegate?.libraryHasNoItems()
//    }
//
//    public func libraryViewShouldAddToSelection(indexPath: IndexPath, numSelections: Int) -> Bool {
//        return pickerVCDelegate?.shouldAddToSelection(indexPath: indexPath, numSelections: numSelections) ?? true
//    }
//}

//Code 3

import UIKit
import Stevia
import Photos
import PhotosUI


protocol YPPickerVCDelegate: AnyObject {
    func libraryHasNoItems()
    func shouldAddToSelection(indexPath: IndexPath, numSelections: Int) -> Bool
}

open class YPPickerVC: YPBottomPager, YPBottomPagerDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate, PHPickerViewControllerDelegate {

    let albumsManager = YPAlbumsManager()
    var shouldHideStatusBar = false
    var initialStatusBarHidden = false
    weak var pickerVCDelegate: YPPickerVCDelegate?
    var selectedImages: [UIImage] = []
    var galleryCollectionView: UICollectionView!

    override open var prefersStatusBarHidden: Bool {
        return (shouldHideStatusBar || initialStatusBarHidden) && YPConfig.hidesStatusBar
    }

    /// Private callbacks to YPImagePicker
    public var didClose:(() -> Void)?
    public var didSelectItems: (([YPMediaItem]) -> Void)?

    enum Mode {
        case library
        case camera
        case video
    }

    private var libraryVC: YPLibraryVC?
    private var cameraVC: YPCameraVC?
    private var videoVC: YPVideoCaptureVC?

    var mode = Mode.camera

    var capturedImage: UIImage?

    open override func viewDidLoad() {
        super.viewDidLoad()

        // Create and configure the collection view layout
               let layout = UICollectionViewFlowLayout()
               layout.itemSize = CGSize(width: 100, height: 100)
               layout.minimumInteritemSpacing = 10
               layout.minimumLineSpacing = 10
        
        
        view.backgroundColor = YPConfig.colors.safeAreaBackgroundColor

        delegate = self

        // Force Library only when using `minNumberOfItems`.
        if YPConfig.library.minNumberOfItems > 1 {
            YPImagePickerConfiguration.shared.screens = [.library]
        }

        // Library
        if YPConfig.screens.contains(.library) {
            libraryVC = YPLibraryVC()
            libraryVC?.delegate = self
        }

        // Camera
        if YPConfig.screens.contains(.photo) {
            cameraVC = YPCameraVC()
            cameraVC?.didCapturePhoto = { [weak self] img in
                self?.didSelectItems?([YPMediaItem.photo(p: YPMediaPhoto(image: img,
                                                                         fromCamera: true))])
            }
        }

        // Video
        if YPConfig.screens.contains(.video) {
            videoVC = YPVideoCaptureVC()
            videoVC?.didCaptureVideo = { [weak self] videoURL in
                self?.didSelectItems?([YPMediaItem
                                        .video(v: YPMediaVideo(thumbnail: thumbnailFromVideoPath(videoURL),
                                                               videoURL: videoURL,
                                                               fromCamera: true))])
            }
        }

        // Show screens
        var vcs = [UIViewController]()
        for screen in YPConfig.screens {
            switch screen {
            case .library:
                if let libraryVC = libraryVC {
                    vcs.append(libraryVC)
                }
            case .photo:
                if let cameraVC = cameraVC {
                    vcs.append(cameraVC)
                }
            case .video:
                if let videoVC = videoVC {
                    vcs.append(videoVC)
                }
            }
        }
        controllers = vcs

        // Select good mode
        if YPConfig.screens.contains(YPConfig.startOnScreen) {
            switch YPConfig.startOnScreen {
            case .library:
                mode = .library
            case .photo:
                mode = .camera
            case .video:
                mode = .video
            }
        }

        // Select good screen
        if let index = YPConfig.screens.firstIndex(of: YPConfig.startOnScreen) {
            startOnPage(index)
        }

        YPHelper.changeBackButtonIcon(self)
        YPHelper.changeBackButtonTitle(self)
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraVC?.v.shotButton.isEnabled = true

        updateMode(with: currentController)
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        shouldHideStatusBar = true
        initialStatusBarHidden = true
        UIView.animate(withDuration: 0.3) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }


    internal func pagerScrollViewDidScroll(_ scrollView: UIScrollView) { }

    func modeFor(vc: UIViewController) -> Mode {
        switch vc {
        case is YPLibraryVC:
            return .library
        case is YPCameraVC:
            return .camera
        case is YPVideoCaptureVC:
            return .video
        default:
            return .camera
        }
    }

    func pagerDidSelectController(_ vc: UIViewController) {
        updateMode(with: vc)
    }

    func updateMode(with vc: UIViewController) {
        stopCurrentCamera()

        // Set new mode
        mode = modeFor(vc: vc)

        // Re-trigger permission check
        if let vc = vc as? YPLibraryVC {
            vc.doAfterLibraryPermissionCheck { [weak vc] in
                vc?.initialize()
            }
        } else if let cameraVC = vc as? YPCameraVC {
            cameraVC.start()
        } else if let videoVC = vc as? YPVideoCaptureVC {
            videoVC.start()
        }

        updateUI()
    }

    func stopCurrentCamera() {
        switch mode {
        case .library:
            libraryVC?.pausePlayer()
        case .camera:
            cameraVC?.stopCamera()
        case .video:
            videoVC?.stopCamera()
        }
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        shouldHideStatusBar = false
    }

    deinit {
        stopAll()
        ypLog("YPPickerVC deinited ✅")
    }

    @objc
    func navBarTapped() {
        guard !(libraryVC?.isProcessing ?? false) else {
            return
        }

        let vc = YPAlbumVC(albumsManager: albumsManager)
        let navVC = UINavigationController(rootViewController: vc)
        navVC.navigationBar.tintColor = .ypLabel

        vc.didSelectAlbum = { [weak self] album in
            self?.libraryVC?.setAlbum(album)
            self?.setTitleViewWithTitle(aTitle: album.title)
            navVC.dismiss(animated: true, completion: nil)
        }
        present(navVC, animated: true, completion: nil)
    }

    func setTitleViewWithTitle(aTitle: String) {
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 200, height: 40)

        let label = UILabel()
        label.text = aTitle
        // Use YPConfig font
        label.font = YPConfig.fonts.pickerTitleFont

        // Use custom textColor if set by user.
        if let navBarTitleColor = UINavigationBar.appearance().titleTextAttributes?[.foregroundColor] as? UIColor {
            label.textColor = navBarTitleColor
        }

        if YPConfig.library.options != nil {
            titleView.subviews(
                label
            )
            |-(>=8)-label.centerHorizontally()-(>=8)-|
            align(horizontally: label)
        } else {
            let arrow = UIImageView()
            arrow.image = YPConfig.icons.arrowDownIcon
            arrow.image = arrow.image?.withRenderingMode(.alwaysTemplate)
            arrow.tintColor = .ypLabel

            let attributes = UINavigationBar.appearance().titleTextAttributes
            if let attributes = attributes, let foregroundColor = attributes[.foregroundColor] as? UIColor {
                arrow.image = arrow.image?.withRenderingMode(.alwaysTemplate)
                arrow.tintColor = foregroundColor
            }

            let button = UIButton()
            button.addTarget(self, action: #selector(navBarTapped), for: .touchUpInside)
            button.setBackgroundColor(UIColor.white.withAlphaComponent(0.5), forState: .highlighted)

            titleView.subviews(
                label,
                arrow,
                button
            )
            button.fillContainer()
            |-(>=8)-label.centerHorizontally()-arrow-(>=8)-|
            align(horizontally: label-arrow)
        }

        label.firstBaselineAnchor.constraint(equalTo: titleView.bottomAnchor, constant: -14).isActive = true

        titleView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        navigationItem.titleView = titleView
    }

    func updateUI() {
        if !YPConfig.hidesCancelButton {
             // Update Nav Bar state.
             let cancelButton = UIBarButtonItem(title: "",
                                                style: .plain,
                                                target: self,
                                                action: #selector(close))
             if #available(iOS 13.0, *) {
                 cancelButton.image = UIImage(systemName: "xmark")
             } else {
                 // Fallback on earlier versions
             }
             
             let manageButton: UIBarButtonItem
             if #available(iOS 13.0, *) {
                 manageButton = UIBarButtonItem(image: UIImage(systemName: "gearshape"),
                                                style: .plain,
                                                target: self,
                                                action: #selector(manageButtonTapped))
                 manageButton.image = UIImage(systemName: "gearshape")
             } else {
                 // Fallback on earlier versions
                 manageButton = UIBarButtonItem(title: "Settings",
                                                style: .plain,
                                                target: self,
                                                action: #selector(manageButtonTapped))
             } // Make sure to call the correct selector
             
             navigationItem.leftBarButtonItems = [cancelButton, manageButton]
         }
        switch mode {
        case .library:
            setTitleViewWithTitle(aTitle: libraryVC?.title ?? "")
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: YPConfig.wordings.next,
                                                                style: .done,
                                                                target: self,
                                                                action: #selector(done))
            navigationItem.rightBarButtonItem?.tintColor = YPConfig.colors.tintColor

            // Disable Next Button until minNumberOfItems is reached.
            navigationItem.rightBarButtonItem?.isEnabled =
                libraryVC!.selectedItems.count >= YPConfig.library.minNumberOfItems

        case .camera:
            navigationItem.titleView = nil
            title = cameraVC?.title
            navigationItem.rightBarButtonItem = nil
        case .video:
            navigationItem.titleView = nil
            title = videoVC?.title
            navigationItem.rightBarButtonItem = nil
        }

        navigationItem.rightBarButtonItem?.setFont(font: YPConfig.fonts.rightBarButtonFont, forState: .normal)
        navigationItem.rightBarButtonItem?.setFont(font: YPConfig.fonts.rightBarButtonFont, forState: .disabled)
        navigationItem.leftBarButtonItem?.setFont(font: YPConfig.fonts.leftBarButtonFont, forState: .normal)
    }


    // MARK: - Actions
    @objc
    func selectMorePhotos() {
        if #available(iOS 14, *) {
            var configuration = PHPickerConfiguration()
            configuration.selectionLimit = 0
            configuration.filter = .images

            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            present(picker, animated: true)
        } else {
            // Fallback on earlier versions
        }
    }

    
    @available(iOS 14, *)
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        let itemProviders = results.map(\.itemProvider)
        for itemProvider in itemProviders {
            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                    if let image = image as? UIImage {
                        DispatchQueue.main.async {
                            // Handle the selected image
                            self?.selectedImages.append(image)
                            // Check if galleryCollectionView is not nil before calling reloadData()
                            if let galleryCollectionView = self?.galleryCollectionView {
                                galleryCollectionView.reloadData()
                            }
                        }
                    }
                }
            }
        }
    }


    
    @objc
    func manageButtonTapped() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        print("Manage button tapped")

        // Select More Photos action
        let selectMorePhotosAction = UIAlertAction(title: "Seleccionar más fotos", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }

        // Change Settings action
        let changeSettingsAction = UIAlertAction(title: "Cambiar configuraciones", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }

        // Cancel action
        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)

        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }

        // Add actions to the actionSheet
        actionSheet.addAction(selectMorePhotosAction)
        actionSheet.addAction(changeSettingsAction)
        actionSheet.addAction(cancelAction)

        // Present action sheet
        self.present(actionSheet, animated: true, completion: nil)
    }

    @objc
    func close() {
        // Cancelling exporting of all videos
        if let libraryVC = libraryVC {
            libraryVC.mediaManager.forseCancelExporting()
        }
        self.didClose?()
    }

    // When pressing "Next"
    @objc
    func done() {
        guard let libraryVC = libraryVC else { ypLog("YPLibraryVC deallocated"); return }

        if mode == .library {
            libraryVC.selectedMedia(photoCallback: { photo in
                self.didSelectItems?([YPMediaItem.photo(p: photo)])
            }, videoCallback: { video in
                self.didSelectItems?([YPMediaItem
                                        .video(v: video)])
            }, multipleItemsCallback: { items in
                self.didSelectItems?(items)
            })
        }
    }

    func stopAll() {
        libraryVC?.v.assetZoomableView.videoView.deallocate()
        videoVC?.stopCamera()
        cameraVC?.stopCamera()
    }
}


extension YPPickerVC: YPLibraryViewDelegate {

    public func libraryViewDidTapNext() {
        libraryVC?.isProcessing = true
        DispatchQueue.main.async {
            self.v.scrollView.isScrollEnabled = false
            self.libraryVC?.v.fadeInLoader()
            self.navigationItem.rightBarButtonItem = YPLoaders.defaultLoader
        }
    }

    public func libraryViewStartedLoadingImage() {
        // TODO remove to enable changing selection while loading but needs cancelling previous image requests.
        libraryVC?.isProcessing = true
        DispatchQueue.main.async {
            self.libraryVC?.v.fadeInLoader()
        }
    }

    public func libraryViewFinishedLoading() {
        libraryVC?.isProcessing = false
        DispatchQueue.main.async {
            self.v.scrollView.isScrollEnabled = YPConfig.isScrollToChangeModesEnabled
            self.libraryVC?.v.hideLoader()
            self.updateUI()
        }
    }

    public func libraryViewDidToggleMultipleSelection(enabled: Bool) {
        var offset = v.header.frame.height
        if #available(iOS 11.0, *) {
            offset += v.safeAreaInsets.bottom
        }

        v.header.bottomConstraint?.constant = enabled ? offset : 0
        v.layoutIfNeeded()
        updateUI()
    }

    public func libraryViewHaveNoItems() {
        pickerVCDelegate?.libraryHasNoItems()
    }

    public func libraryViewShouldAddToSelection(indexPath: IndexPath, numSelections: Int) -> Bool {
        return pickerVCDelegate?.shouldAddToSelection(indexPath: indexPath, numSelections: numSelections) ?? true
    }
}
