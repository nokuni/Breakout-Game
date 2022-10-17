//
//  ContentView.swift
//  BreakoutGameProject
//
//  Created by Yann Christophe Maertens on 30/12/2021.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    @EnvironmentObject var gameScene: GameScene
    var body: some View {
        SpriteView(scene: gameScene)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(GameScene())
    }
}
