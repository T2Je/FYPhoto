//
//  PhotoBrowserViewController+Builder.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/1/18.
//

import Foundation

extension PhotoBrowserViewController {
    public class Builder {
        var selectedPhotos: [PhotoProtocol] = []
        /// maximum photos can be selected. Default is 6
        var maximumCanBeSelected: Int = 6
        var isForSelection = false

        /// 选择照片时，在底部展示缩略图
        var supportThumbnails = false

        /// ACDM 随手拍底部展示图片的标题
        var supportCaption = false

        /// 显示 navigationBar, contains title，添加，取消添加 bar item
        var supportNavigationBar = false
        /// 显示 bottom tool bar, contains play video bar item, complete selection bar item
        var supportBottomToolBar = false

        /// show delete button for photo browser
        var canDeleteWhenPreviewingSelectedPhotos = false

        var supportPageControl = false

        init() { }

        public func setSelectedPhotos(_ selected: [PhotoProtocol]) -> Self {
            selectedPhotos = selected
            return self
        }

        public func setMaximumCanBeSelected(_ maximum: Int) -> Self {
            maximumCanBeSelected = maximum
            return self
        }

        /// Add a delete button in the upper right corner of the photo when you only browse the photos without selecting them
        /// 只浏览照片不选择照片时在照片右上角加删除按钮
        /// - Returns: Builder
        public func showDeleteButtonForBrowser() -> Self {
            canDeleteWhenPreviewingSelectedPhotos = true
            supportNavigationBar = true
            return self
        }

        public func buildForSelection(_ isForSelection: Bool) -> Self {
            self.isForSelection = isForSelection
            return self
        }

        public func buildThumbnailsForSelection() -> Self {
            self.supportThumbnails = true
            return self
        }

        /// ACDM 随手拍照片底部有标题
        /// - Returns: Builder
        public func buildCaption() -> Self {
            self.supportCaption = true
            return self
        }

        public func buildNavigationBar() -> Self {
            self.supportNavigationBar = true
            return self
        }

        /// Build bottom bar for play video bar button and done bar button.
        /// If datasource has videos, PhotoBrowser will support bottomTooBar by default.
        /// - Returns: Self
        public func buildBottomToolBar() -> Self {
            self.supportBottomToolBar = true
            return self
        }

        public func buildPageControl() -> Self {
            self.supportPageControl = true
            return self
        }

        /// 快速创建一个 builder，用来展示图片并支持选择图片。不包含删除按钮
        /// Quick builder for photo picker to use which mean you can select, unselect photos and submit your selection
        /// - Parameters:
        ///   - selected: already selected photos
        ///   - maximumCanBeSelected: maximum photos can be selected.
        /// - Returns: Builder
        public func quickBuildForSelection(_ selected: [PhotoProtocol], maximumCanBeSelected: Int) -> Self {
            isForSelection = true
            supportThumbnails = true
            supportNavigationBar = true
            supportBottomToolBar = true
            supportCaption = false
            canDeleteWhenPreviewingSelectedPhotos = false
            supportPageControl = false
            self.maximumCanBeSelected = maximumCanBeSelected
            self.selectedPhotos = selected
            return self
        }

        /// 快速创建一个 builder，用来展示图片。不包含删除按钮
        /// Quick builder just for browsing photos which means you cannot select or unselect photo.
        /// - Returns: Builder
        public func quickBuildJustForBrowser() -> Self {
            isForSelection = false
            supportThumbnails = false
            supportNavigationBar = false
            supportBottomToolBar = false
            supportCaption = true
            canDeleteWhenPreviewingSelectedPhotos = false
            supportPageControl = true
            self.maximumCanBeSelected = 0
            self.selectedPhotos = []
            return self
        }

        public func build(_ photoBrowser: PhotoBrowserViewController) {
            photoBrowser.maximumCanBeSelected = maximumCanBeSelected
            photoBrowser.isForSelection = isForSelection
            photoBrowser.supportThumbnails = supportThumbnails
            photoBrowser.supportCaption = supportCaption
            photoBrowser.supportNavigationBar = supportNavigationBar
            photoBrowser.supportBottomToolBar = supportBottomToolBar || photoBrowser.photos.contains { $0.isVideo }
            photoBrowser.canDeleteWhenPreviewingSelectedPhotos = canDeleteWhenPreviewingSelectedPhotos
            photoBrowser.supportPageControl = supportPageControl
            photoBrowser.selectedPhotos = selectedPhotos
        }
    }
}
