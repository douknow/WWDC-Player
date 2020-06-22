//
//  SceneDelegate.swift
//  WWDCPlayer
//
//  Created by Xianzhao Han on 2020/3/2.
//  Copyright © 2020 lcrystal. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    let coreDataStack = ContainerService.shared.coreDataStack


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }

        setupToolBar(scene)

        window = UIWindow(windowScene: scene)

        let rootVC = RootSplitViewController()
        rootVC.coreDataStack = coreDataStack
        let videoService = VideoService(coreDataStack: coreDataStack)
        rootVC.videoService = videoService
        window?.rootViewController = rootVC
        window?.makeKeyAndVisible()
    }

    func setupToolBar(_ scene: UIScene) {
        #if targetEnvironment(macCatalyst)
        if let scene = scene as? UIWindowScene,
            let titleBar = scene.titlebar {
            titleBar.autoHidesToolbarInFullScreen = true
            titleBar.titleVisibility = .hidden

            let toolBar = NSToolbar(identifier: "toolbar")
            titleBar.toolbar = toolBar
            toolBar.delegate = self
            toolBar.allowsUserCustomization = false
            toolBar.displayMode = .iconOnly
        }
        #endif
    }

}

#if targetEnvironment(macCatalyst)

extension NSToolbarItem.Identifier {
    static let openInWeb = NSToolbarItem.Identifier("open-in-web")
    static let leftWindow = NSToolbarItem.Identifier("left-window")
}

extension SceneDelegate: NSToolbarDelegate {

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.openInWeb, .leftWindow]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.leftWindow, .flexibleSpace, .openInWeb]
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        var item: NSToolbarItem? = nil

        switch itemIdentifier {
        case .openInWeb:

            let barButtonItem = UIBarButtonItem(image: UIImage(systemName: "safari"), style: .plain, target: self, action: #selector(openInWeb))
            item = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: barButtonItem)
            item?.toolTip = "Open in web"
            item?.label = "Open in web"
            item?.target = self
            item?.action = #selector(openInWeb)

        case .leftWindow:
            let barButtonItem = UIBarButtonItem(image: UIImage(systemName: "sidebar.left"), style: .plain, target: self, action: #selector(openInWeb))
            item = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: barButtonItem)
            item?.toolTip = "Hide or show Side bar"
            item?.label = ""
            item?.target = self
            item?.action = #selector(leftWindowAction)
        default:
            break
        }
        return item
    }

    @objc func openInWeb() {
        let splitVC = (window?.rootViewController as! UISplitViewController)
        let detailVC = splitVC.viewControllers.last as! VideoDetailContainerViewController
        if let relatedURL = detailVC.video?.urlStr {
            let url = WWDCService.Endpoint.basic.appendingPathComponent(relatedURL)
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    @objc func leftWindowAction() {
        let splitVC = (window?.rootViewController as! UISplitViewController)
        if splitVC.displayMode == .allVisible {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn], animations: {
                splitVC.preferredDisplayMode = .primaryHidden
            }, completion: nil)
        } else {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
                splitVC.preferredDisplayMode = .allVisible
            }, completion: nil)
        }
    }

}

#endif
