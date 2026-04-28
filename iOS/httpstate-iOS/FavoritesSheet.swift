// HTTPState, https://httpstate.com/
// Copyright (C) Alex Morales, 2026
//
// Unless otherwise stated in particular files or directories, this software is free software.
// You can redistribute it and/or modify it under the terms of the GNU Affero
// General Public License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.

import SwiftUI

struct FavoritesSheet: View {
    @Bindable var model: HTTPStateViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if model.favoritesStore.favorites.isEmpty {
                        Text("No favorites yet. Tap + to add one.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(model.favoritesStore.favorites) { favorite in
                            Button {
                                model.selectFavorite(favorite)
                                dismiss()
                            } label: {
                                FavoriteRow(
                                    favorite: favorite,
                                    isCurrent: favorite.uuid == model.canonicalUUIDForDisplay
                                )
                            }
                        }
                        .onDelete { offsets in
                            model.removeFavorites(at: offsets)
                        }
                    }
                }

                Section {
                    ShareLink(item: model.favoritesStore.storeUUID) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Tap to share or copy")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(model.favoritesStore.storeUUID)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.tint)
                        }
                    }
                } header: {
                    Text("Sync ID")
                } footer: {
                    Text("Save this ID to restore your favorites on another device or after reinstalling.")
                }
            }
            .navigationTitle("Favorites")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddFavoriteSheet(currentUUID: model.canonicalUUIDForDisplay) { name, uuid in
                    model.addFavorite(Favorite(name: name, uuid: uuid))
                }
            }
        }
    }
}

private struct FavoriteRow: View {
    let favorite: Favorite
    let isCurrent: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(favorite.name.isEmpty ? "Unnamed" : favorite.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(favorite.uuid)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            if isCurrent {
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
            }
        }
    }
}

private struct AddFavoriteSheet: View {
    let currentUUID: String
    let onAdd: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var uuidInput: String = ""

    private var canonical: String? { canonicalUUID(uuidInput) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Optional label", text: $name)
                }
                Section {
                    TextField("UUID", text: $uuidInput)
                        .font(.system(.body, design: .monospaced))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Use current UUID") {
                        uuidInput = currentUUID
                    }
                    .buttonStyle(.borderless)
                } header: {
                    Text("UUID")
                } footer: {
                    if !uuidInput.isEmpty && canonical == nil {
                        Text("Not a valid UUID. Accepts dashed or undashed, any case.")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add Favorite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let canonical {
                            onAdd(name.trimmingCharacters(in: .whitespacesAndNewlines), canonical)
                            dismiss()
                        }
                    }
                    .disabled(canonical == nil)
                }
            }
        }
    }
}
