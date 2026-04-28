// HTTPState, https://httpstate.com/
// Copyright (C) Alex Morales, 2026
//
// Unless otherwise stated in particular files or directories, this software is free software.
// You can redistribute it and/or modify it under the terms of the GNU Affero
// General Public License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.

import SwiftUI

private let httpStatePurple = Color(red: 152/255, green: 126/255, blue: 184/255)

struct ContentView: View {
    @State private var model = HTTPStateViewModel()
    @State private var showingFavorites = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text("HTTPState")
                    .font(.system(size: 22, weight: .bold))
                    .tracking(0.2)
                    .foregroundStyle(.white)
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

            Spacer(minLength: 24)

            ScrollView(.vertical, showsIndicators: false) {
                Text(model.value)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxHeight: .infinity)

            Spacer(minLength: 16)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    TextField("Write a value…", text: $model.pendingValue)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.white)
                        .tint(.white)
                        .submitLabel(.send)
                        .onSubmit { model.writePending() }

                    Button {
                        model.writePending()
                    } label: {
                        Text("Set")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.white, in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(httpStatePurple)
                    }
                    .buttonStyle(.plain)
                    .disabled(model.pendingValue.isEmpty || model.isWriting)
                    .opacity(model.pendingValue.isEmpty || model.isWriting ? 0.5 : 1)
                }
                if let writeError = model.writeError {
                    Text(writeError)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }

            Spacer(minLength: 24)

            HStack {
                Button {
                    model.reload()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .accessibilityLabel("Refresh")
                }
                .buttonStyle(.plain)

                Spacer()

                Text("At \(model.retrievedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(28)
        .background(httpStatePurple.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 10) {
                Image(systemName: "eye")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                TextField("UUID", text: $model.uuid)
                    .font(.system(.callout, design: .monospaced))
                    .foregroundStyle(.white)
                    .tint(.white)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .onSubmit { model.reload() }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .onAppear { model.start() }
        .onChange(of: scenePhase) {
            if scenePhase == .active { model.reload() }
        }
        .sheet(isPresented: $showingFavorites) {
            FavoritesSheet(model: model)
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
