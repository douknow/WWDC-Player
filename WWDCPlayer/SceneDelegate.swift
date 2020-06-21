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

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    func setupToolBar(_ scene: UIScene) {
        #if targetEnvironment(macCatalyst)
        if let scene = scene as? UIWindowScene,
            let titleBar = scene.titlebar {

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
}

extension SceneDelegate: NSToolbarDelegate {

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.openInWeb]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.flexibleSpace, .openInWeb]
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        var item: NSToolbarItem? = nil
        let barButtonItem = UIBarButtonItem(image: UIImage(systemName: "safari"), style: .plain, target: self, action: #selector(openInWeb))
        item = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: barButtonItem)
        item?.toolTip = "Open in web"
        item?.label = "Open in web"
        item?.target = self
        item?.action = #selector(openInWeb)
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

}

#endif
