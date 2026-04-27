// HTTPState, https://httpstate.com/
// Copyright (C) Alex Morales, 2026
//
// Unless otherwise stated in particular files or directories, this software is free software.
// You can redistribute it and/or modify it under the terms of the GNU Affero
// General Public License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.

import SwiftUI

struct FavoritesSheet: View {
    @Binding var favorites: [Favorite]
    let currentUUID: String
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            List {
                if favorites.isEmpty {
                    ContentUnavailableView(
                        "No favorites yet",
                        systemImage: "star",
                        description: Text("Save the UUIDs you watch often.")
                    )
                } else {
                    ForEach(favorites) { fav in
                        Button {
                            onSelect(fav.uuid)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(fav.name.isEmpty ? "Unnamed" : fav.name)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    Text(fav.uuid)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                Spacer()
                                if fav.uuid == currentUUID {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                    }
                    .onDelete { indices in
                        favorites.remove(atOffsets: indices)
                    }
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
                AddFavoriteSheet(currentUUID: currentUUID) { name, uuid in
                    favorites.append(Favorite(name: name, uuid: uuid))
                }
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
