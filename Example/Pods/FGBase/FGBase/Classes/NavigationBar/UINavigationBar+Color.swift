//
//  UINavigationBar+Color.swift
//  FGBase
//
//  Created by kun wang on 2019/09/04.
//

import Foundation

/*
 如果发现导航栏在转场过程中出现了样式错乱，可以遵循以下几点基本原则：

 检查相应 ViewController 里是否有修改其他 ViewController 导航栏样式的行为，如果有，请做调整。
 保证所有对导航栏样式变化的操作出现在 viewDidLoad 和 viewWillAppear: 中，如果在 viewWillDisappear: 等方法里出现了对导航栏的样式修改的操作，如果有，请做调整。
 检查是否有改动 translucent 属性，包括显示修改和隐式修改，如果有，请做调整。

 只关心当前页面的样式
    永远记住每个 ViewController 只用关心自己的样式，设置的时机点在 viewWillAppear: 或者 viewDidLoad 里。

 一些解释
 在设置透明效果时，我们通常可以直接设置一个 [UIImage new] 创建的对象，无须创建一个颜色为透明色的图片。
 在使用 setBackgroundImage:forBarMetrics: 方法的过程中，如果图像里存在 alpha 值小于 1.0 的像素点，则 translucent 的值为 YES，反之为 NO。也就是说，如果我们真的想让导航栏变成纯色且没有 translucent 效果，请保证所有像素点的 alpha 值等于 1。
 如果设置了一个完全不透明的图片且强行将 NavigationBar 的 translucent 属性设置为 YES 的话，系统会自动修正这个图片并为它添加一个透明度，用于模拟 translucent 效果。
 如果我们使用了一个带有透明效果的图片且导航栏的 translucent 效果为 NO 的话，那么系统会在这个带有透明效果的图片背后，添加一个不透明的纯色图片用于整体效果的合成。这个纯色图片的颜色取决于 barStyle 属性，当属性为 UIBarStyleBlack 时为黑色，当属性为 UIBarStyleDefault 时为白色，如果我们设置了 barTintColor，则以设置的颜色为基准。
 */
extension UINavigationBar {
    //设置导航栏透明 透明样式导航栏的正确设置方法
    @objc public func fg_setTransparent() {
        setBackgroundImage(UIImage(), for: .default)
        shadowImage = UIImage()
    }

    //更改导航栏颜色，也可以用来改变导航栏的透明度，
    // 注意1 如果前后两个 navigationBar的颜色，不一样，用这种方式，在滑动返回时可明显看到颜色的跳变
    // 注意2 用来改变导航栏的透明度，应该使用 color的alpha，来改变导航栏的透明度，如果需要导航栏实现随滚动改变整体 alpha 值的效果，这里一般是使用监听 scrollView.contentOffset 的手段来做。请避免直接修改 NavigationBar 的 alpha 值。
    //还有一点需要注意的是，在页面转场的过程中，也会触发 contentOffset 的变化，所以请尽量在 disappear 的时候取消监听。否则会容易出现导航栏透明度的变化。
    @objc public func fg_changeColor(_ color: UIColor) {
        setBackgroundImage(UIImage(color: color), for: .default)
    }
}
