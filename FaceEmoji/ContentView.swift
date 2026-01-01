//
//  ContentView.swift
//  FaceEmoji
//
//  Created on $(DATE)
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "face.smiling")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("FaceEmoji")
                .font(.title)
            Text("Open Messages to use the extension")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

