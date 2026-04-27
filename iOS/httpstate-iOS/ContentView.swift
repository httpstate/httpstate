// HTTPState, https://httpstate.com/
// Copyright (C) Alex Morales, 2026
//
// Unless otherwise stated in particular files or directories, this software is free software.
// You can redistribute it and/or modify it under the terms of the GNU Affero
// General Public License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.

import Combine
import HTTPStateClient
import SwiftUI
import WidgetKit

private let httpStateClient: HTTPStateClient = {
    let cfg = URLSessionConfiguration.default
    cfg.requestCachePolicy = .reloadIgnoringLocalCacheData
    cfg.urlCache = nil
    return HTTPStateClient(configuration: HTTPStateConfiguration(
        endpoint: URL(string: "https://httpstate.com")!,
        webSocketEndpoint: URL(string: "wss://httpstate.com")!,
        transport: URLSessionTransport(session: URLSession(configuration: cfg))
    ))
}()

struct ContentView: View {
    @State private var value: String = "—"
    @State private var retrievedAt: Date = .now
    @AppStorage("uuid") private var uuid: String = "45fb36540e9244daaa21ca409c6bdab3"
    @Environment(\.scenePhase) var scenePhase

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("HTTPState")
                        .font(.system(size: 22, weight: .bold))
                        .tracking(0.2)
                        .foregroundStyle(.white)
                    TextField("UUID", text: $uuid, onCommit: reloadData)
                        .font(.system(size: 16, weight: .regular, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                        .tint(.white.opacity(0.7))
                        .lineLimit(1)
                }
                Spacer()
                MascotIcon(size: 52)
            }

            Spacer(minLength: 24)

            Text(value)
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Spacer(minLength: 24)

            HStack {
                Spacer()
                Text("At \(retrievedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(28)
        .background(Color(red: 152/255, green: 126/255, blue: 184/255).ignoresSafeArea())
        .onAppear {
            reloadData()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                reloadData()
            }
        }
        .onReceive(timer) { _ in
            reloadData()
        }
    }

    private func reloadData() {
        Task {
            let next: String
            do {
                next = try await httpStateClient.get(uuid) ?? "—"
            } catch {
                next = "Error"
            }
            value = next
            retrievedAt = Date()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

struct MascotIcon: View {
    var size: CGFloat

    var body: some View {
        Circle()
            .fill(.white)
            .frame(width: size, height: size)
            .overlay(
                Image("Mascot")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(Circle())
                    .padding(3)
            )
    }
}

#Preview {
    ContentView()
}
