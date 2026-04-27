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

private let httpStatePurple = Color(red: 152/255, green: 126/255, blue: 184/255)

struct ContentView: View {
    @AppStorage("uuid") private var uuid: String = "45fb36540e9244daaa21ca409c6bdab3"
    @AppStorage("favorites_v1") private var favoritesData: Data = Data()

    @State private var value: String = "—"
    @State private var retrievedAt: Date = .now
    @State private var pendingValue: String = ""
    @State private var isWriting = false
    @State private var writeError: String?
    @State private var showingFavorites = false
    @Environment(\.scenePhase) private var scenePhase

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var favorites: [Favorite] {
        (try? JSONDecoder().decode([Favorite].self, from: favoritesData)) ?? []
    }

    private var favoritesBinding: Binding<[Favorite]> {
        Binding(
            get: { favorites },
            set: { newValue in
                favoritesData = (try? JSONEncoder().encode(newValue)) ?? Data()
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Spacer(minLength: 24)

            Text(value)
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Spacer(minLength: 16)

            writeRow

            Spacer(minLength: 24)

            footer
        }
        .padding(28)
        .background(httpStatePurple.ignoresSafeArea())
        .onAppear { reloadData() }
        .onChange(of: scenePhase) {
            if scenePhase == .active { reloadData() }
        }
        .onReceive(timer) { _ in reloadData() }
        .sheet(isPresented: $showingFavorites) {
            FavoritesSheet(
                favorites: favoritesBinding,
                currentUUID: canonicalUUID(uuid) ?? uuid,
                onSelect: { newUUID in
                    uuid = newUUID
                    showingFavorites = false
                    reloadData()
                }
            )
        }
    }

    private var header: some View {
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
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            Spacer()
            Button {
                showingFavorites = true
            } label: {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                    .accessibilityLabel("Favorites")
            }
            .buttonStyle(.plain)
            MascotIcon(size: 52)
        }
    }

    private var writeRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                TextField("Write a value…", text: $pendingValue)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
                    .tint(.white)
                    .submitLabel(.send)
                    .onSubmit(writePendingValue)

                Button {
                    writePendingValue()
                } label: {
                    Text("Set")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.white, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(httpStatePurple)
                }
                .buttonStyle(.plain)
                .disabled(pendingValue.isEmpty || isWriting)
                .opacity(pendingValue.isEmpty || isWriting ? 0.5 : 1)
            }
            if let err = writeError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    private var footer: some View {
        HStack {
            Button {
                reloadData()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .accessibilityLabel("Refresh")
            }
            .buttonStyle(.plain)

            Spacer()

            Text("At \(retrievedAt.formatted(date: .omitted, time: .shortened))")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.white.opacity(0.7))
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

    private func writePendingValue() {
        let toWrite = pendingValue
        guard !toWrite.isEmpty, !isWriting else { return }
        Task {
            isWriting = true
            writeError = nil
            do {
                try await httpStateClient.set(uuid, toWrite)
                pendingValue = ""
                reloadData()
            } catch {
                writeError = "Couldn't write: \(error)"
            }
            isWriting = false
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
