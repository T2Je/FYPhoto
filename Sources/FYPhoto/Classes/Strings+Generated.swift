// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// 想访问您的照片
  internal static let accessPhotoLibraryTitle = L10n.tr("FYPhoto", "AccessPhotoLibraryTitle")
  /// 无法访问相册中照片
  internal static let accessPhotosFailed = L10n.tr("FYPhoto", "AccessPhotosFailed")
  /// 当前无照片访问权限，建议前往系统设置
  internal static let accessPhotosFailedMessage = L10n.tr("FYPhoto", "AccessPhotosFailedMessage")
  /// 添加
  internal static let add = L10n.tr("FYPhoto", "add")
  /// 最近项目
  internal static let allPhotos = L10n.tr("FYPhoto", "AllPhotos")
  /// 相机
  internal static let camera = L10n.tr("FYPhoto", "Camera")
  /// 无法拍摄视频
  internal static let cameraConfigurationFailed = L10n.tr("FYPhoto", "CameraConfigurationFailed")
  /// 取消
  internal static let cancel = L10n.tr("FYPhoto", "Cancel")
  /// 确定
  internal static let confirm = L10n.tr("FYPhoto", "Confirm")
  /// 裁剪
  internal static let cropPhoto = L10n.tr("FYPhoto", "CropPhoto")
  /// 放弃修改
  internal static let discardChanges = L10n.tr("FYPhoto", "DiscardChanges")
  /// 完成
  internal static let done = L10n.tr("FYPhoto", "Done")
  /// 保存失败
  internal static let failedToSaveMedia = L10n.tr("FYPhoto", "FailedToSaveMedia")
  /// 前置/后置
  internal static let frontRear = L10n.tr("FYPhoto", "Front/Rear")
  /// 知道了
  internal static let gotIt = L10n.tr("FYPhoto", "GotIt")
  /// 前往设置
  internal static let goToSettings = L10n.tr("FYPhoto", "GoToSettings")
  /// 小时
  internal static let hour = L10n.tr("FYPhoto", "hour")
  /// 保留当前所选内容
  internal static let keepCurrent = L10n.tr("FYPhoto", "KeepCurrent")
  /// 没有权限将照片存储到相册中
  internal static let noPermissionToSave = L10n.tr("FYPhoto", "NoPermissionToSave")
  /// URL不是一个视频
  internal static let noVideo = L10n.tr("FYPhoto", "NoVideo")
  /// 好的
  internal static let ok = L10n.tr("FYPhoto", "OK")
  /// 原始尺寸
  internal static let orinial = L10n.tr("FYPhoto", "Orinial")
  /// 照片
  internal static let photo = L10n.tr("FYPhoto", "photo")
  /// 预览
  internal static let preview = L10n.tr("FYPhoto", "Preview")
  /// 还原
  internal static let resetPhoto = L10n.tr("FYPhoto", "ResetPhoto")
  /// 恢复
  internal static let resume = L10n.tr("FYPhoto", "Resume")
  /// 保存
  internal static let save = L10n.tr("FYPhoto", "Save")
  /// 保存图片
  internal static let savePhoto = L10n.tr("FYPhoto", "SavePhoto")
  /// 保存视频
  internal static let saveVideo = L10n.tr("FYPhoto", "SaveVideo")
  /// 选择
  internal static let select = L10n.tr("FYPhoto", "Select")
  /// 选择更多照片...
  internal static let selectMorePhotos = L10n.tr("FYPhoto", "SelectMorePhotos")
  /// 设置
  internal static let settings = L10n.tr("FYPhoto", "Settings")
  /// 分类相簿
  internal static let smartAlbums = L10n.tr("FYPhoto", "Smart Albums")
  /// 正方形
  internal static let square = L10n.tr("FYPhoto", "Square")
  /// 已保存到相册
  internal static let successfullySavedMedia = L10n.tr("FYPhoto", "SuccessfullySavedMedia")
  /// 无法恢复
  internal static let unableToResume = L10n.tr("FYPhoto", "Unable to resume")
  /// 不支持的文件格式
  internal static let unspportedVideoFormat = L10n.tr("FYPhoto", "UnspportedVideoFormat")
  /// 自定义相簿
  internal static let userAlbums = L10n.tr("FYPhoto", "User Albums")
  /// 视频时间过长，请重新选择
  internal static let videoDurationTooLong = L10n.tr("FYPhoto", "VideoDurationTooLong")
  /// 文件过大，请重新选择
  internal static let videoMemoryOutOfSize = L10n.tr("FYPhoto", "VideoMemoryOutOfSize")
  /// 没有使用相机的权限，请修改权限设置
  internal static let withoutCameraPermission = L10n.tr("FYPhoto", "WithoutCameraPermission")
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    guard let url = Bundle(for: BundleToken.self).url(forResource: "FYPhoto", withExtension: "bundle") else {
        return .main
    }
    return Bundle(url: url) ?? .main
    #endif
  }()
}
// swiftlint:enable convenience_type

