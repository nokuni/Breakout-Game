//
//  BreakoutGameProjectApp.swift
//  BreakoutGameProject
//
//  Created by Yann Christophe Maertens on 30/12/2021.
//

import SwiftUI

@main
struct BreakoutGameProjectApp: App {
    @StateObject var gameScene = GameScene()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameScene)
        }
    }
}
