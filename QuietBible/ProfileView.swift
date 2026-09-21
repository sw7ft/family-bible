import SwiftUI

struct ProfileButton: View {
    @EnvironmentObject private var store: ReadingStore
    @State private var showSheet = false

    var body: some View {
        Button { showSheet = true } label: {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 17, weight: .ultraLight))
                .foregroundStyle(store.theme.mute.opacity(0.72))
                .frame(width: 22, height: 22)
                .padding(8)
        }
        .accessibilityLabel("Profiles")
        .accessibilityHint(store.currentProfile.map { "Now \($0.name)" } ?? "Switch reader")
        .sheet(isPresented: $showSheet) {
            ProfileSheet()
                .environmentObject(store)
        }
    }
}

struct ProfileSheet: View {
    @EnvironmentObject private var store: ReadingStore
    @Environment(\.dismiss) private var dismiss
    @State private var draftName = ""
    @State private var renaming: BibleProfile?
    @State private var adding = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(store.profiles) { profile in
                        Button {
                            store.switchProfile(profile.id)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(profile.name)
                                        .font(QuietFont.display(20))
                                        .foregroundStyle(store.theme.ink)
                                    if profile.id == store.profileId {
                                        Text("Reading now")
                                            .font(QuietFont.small(12))
                                            .foregroundStyle(store.theme.accent)
                                    }
                                }
                                Spacer()
                                if profile.id == store.profileId {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(store.theme.accent)
                                }
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Rename") {
                                renaming = profile
                                draftName = profile.name
                            }
                            .tint(store.theme.accent)
                            if store.profiles.count > 1 {
                                Button("Delete", role: .destructive) {
                                    store.deleteProfile(profile.id)
                                }
                            }
                        }
                    }
                } footer: {
                    Text("Each person keeps their own notes, comments, journal, devotions, prayers, and marked places. Comments still show on the verse for the whole family.")
                        .font(QuietFont.small(13))
                        .foregroundStyle(store.theme.mute)
                }

                Section {
                    Button {
                        draftName = ""
                        adding = true
                    } label: {
                        Label("Add a profile", systemImage: "plus")
                            .foregroundStyle(store.theme.accent)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(store.theme.page)
            .navigationTitle("Profiles")
            .navigationBarTitleDisplayMode(.inline)
            .quietBar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("New profile", isPresented: $adding) {
                TextField("Name", text: $draftName)
                Button("Add") { store.addProfile(named: draftName) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Notes and journal for this person stay with them.")
            }
            .alert("Rename", isPresented: Binding(
                get: { renaming != nil },
                set: { if !$0 { renaming = nil } }
            )) {
                TextField("Name", text: $draftName)
                Button("Save") {
                    if let renaming {
                        store.renameProfile(renaming.id, to: draftName)
                    }
                    renaming = nil
                }
                Button("Cancel", role: .cancel) { renaming = nil }
            }
        }
        .preferredColorScheme(store.theme.scheme)
    }
}
