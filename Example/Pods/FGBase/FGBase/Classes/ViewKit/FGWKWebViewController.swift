//
//  FGWKWebViewController.swift
//  FGBase
//
//  Created by xiaoyang on 2018/9/12.
//

import UIKit
import WebKit
import SnapKit

open class FGWKWebViewController: UIViewController {
    public var webView: WKWebView
    private var progressBar = UIProgressView()
    var backButton: UIButton?
    var canGoBackOnFirstPage: Bool

    var url: URL?
    var urlRequest: URLRequest?

    private let kWebProgressKeypath = "estimatedProgress"

    convenience public init(urlStr: String, canGoBackOnFirstPage flag: Bool = false) {
        if let url = URL(string: urlStr) {
            self.init(url: url, canGoBackOnFirstPage: flag)
        } else {
            self.init(urlRequest: nil, script: nil, canGoBackOnFirstPage: flag)
        }
    }

    convenience public init(url: URL, canGoBackOnFirstPage flag: Bool = false) {
        self.init(urlRequest: URLRequest(url: url), script: nil, canGoBackOnFirstPage: flag)
        self.url = url
    }

    public init(urlRequest: URLRequest?, script:WKUserScript?, canGoBackOnFirstPage flag: Bool = false) {
        self.canGoBackOnFirstPage = flag
        self.urlRequest = urlRequest
        if let script = script {
            let userContent = WKUserContentController()
            userContent.addUserScript(script)
            let webConfiguration = WKWebViewConfiguration()
            webConfiguration.userContentController = userContent
            webView = WKWebView(frame: .zero, configuration: webConfiguration)
        } else {
            webView = WKWebView()
        }

        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = FGUIConfiguration.shared.bgColor
        guard let request = urlRequest else { return }
        webView.load(request)
        webView.navigationDelegate = self
        webView.uiDelegate = self

        progressBar.progressTintColor = .blue
        progressBar.trackTintColor = .white
        self.view.addSubview(webView)
        self.view.addSubview(progressBar)

        setupView()
        // Do any additional setup after loading the view.
    }

    public func setProgressBar(progressTintColor: UIColor, trackTintColor: UIColor) {
        progressBar.progressTintColor = progressTintColor
        progressBar.trackTintColor = trackTintColor
    }

    @objc func backAction() {
        if self.webView.canGoBack {
            self.webView.goBack()
        } else if canGoBackOnFirstPage {
            if self.fg_isModal() {
                self.dismiss(animated: true)
            } else {
                navigationController?.popViewController(animated: true)
            }
        }
    }

    func setupView() {
        backButton = self.fg_defaultBackBarButton()
        backButton?.isHidden = true
        backButton?.addTarget(self, action: #selector(backAction), for: .touchUpInside)

        progressBar.snp.makeConstraints { (make) in
            if #available(iOS 11.0, *) {
                make.top.equalTo(self.view.safeAreaLayoutGuide).offset(2)
                make.leading.trailing.equalTo(self.view.safeAreaLayoutGuide)
            } else {
                make.top.leading.trailing.equalToSuperview()
            }
            make.height.equalTo(2)
        }

        webView.snp.makeConstraints { (make) in
            if #available(iOS 11.0, *) {
                make.edges.equalTo(self.view.safeAreaLayoutGuide)
            } else {
                // Fallback on earlier versions
                make.edges.equalToSuperview()
            }
        }
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.webView.addObserver(self, forKeyPath: kWebProgressKeypath, options: NSKeyValueObservingOptions.new, context: nil)
        self.progressBar.setProgress(0, animated: false)
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.webView.removeObserver(self, forKeyPath: kWebProgressKeypath)
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension FGWKWebViewController {
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let change = change else { return }
        if keyPath == kWebProgressKeypath {
            if let newProgress = change[NSKeyValueChangeKey.newKey] as? Float , let oldProgress = change[NSKeyValueChangeKey.oldKey] as? Float {
                //不要让进度条倒着走...有时候goback会出现这种情况
                if newProgress < oldProgress {
                    return
                }
                self.progressBar.setProgress(newProgress, animated: true)
                print(newProgress)
            }
        }
    }
}

extension FGWKWebViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print(#function)
        self.progressBar.isHidden = false
    }

    fileprivate func backButtonHiddenJudge() {

        if self.webView.canGoBack {
            backButton?.isHidden = !self.webView.canGoBack
        } else {
            backButton?.isHidden = !canGoBackOnFirstPage
        }
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print(#function)
        self.progressBar.isHidden = true
        backButtonHiddenJudge()
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.showTips(error: error, container: self.view)
        backButtonHiddenJudge()
    }
}


extension FGWKWebViewController: WKUIDelegate {

}
