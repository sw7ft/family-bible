import SwiftUI
import UIKit
import PhotosUI

enum NotePhotos {
    static var directory: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let base = support.appendingPathComponent("FamilyBible/note-photos", isDirectory: true)
        let legacy = support.appendingPathComponent("QuietBible/note-photos", isDirectory: true)
        if FileManager.default.fileExists(atPath: legacy.path), !FileManager.default.fileExists(atPath: base.path) {
            try? FileManager.default.createDirectory(at: base.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? FileManager.default.moveItem(at: legacy, to: base)
        }
        if !FileManager.default.fileExists(atPath: base.path) {
            try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        }
        return base
    }

    static func url(_ id: String) -> URL {
        directory.appendingPathComponent("\(id).jpg")
    }

    static func save(_ image: UIImage) -> String? {
        let id = UUID().uuidString
        let fitted = fit(image, longest: 1600)
        guard let data = fitted.jpegData(compressionQuality: 0.78) else { return nil }
        do {
            try data.write(to: url(id), options: .atomic)
            return id
        } catch {
            return nil
        }
    }

    static func load(_ id: String) -> UIImage? {
        UIImage(contentsOfFile: url(id).path)
    }

    static func delete(_ id: String) {
        try? FileManager.default.removeItem(at: url(id))
    }

    static func delete(_ ids: [String]) {
        ids.forEach(delete)
    }

    private static func fit(_ image: UIImage, longest limit: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > limit else { return image }
        let scale = limit / longest
        let next = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: next, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: next))
        }
    }
}

struct NotePhotoFilm: View {
    @EnvironmentObject private var store: ReadingStore
    let ids: [String]
    var onRemove: ((String) -> Void)? = nil
    @State private var open: String?

    var body: some View {
        if !ids.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ids, id: \.self) { id in
                        ZStack(alignment: .topTrailing) {
                            Button {
                                open = id
                            } label: {
                                NotePhotoThumb(id: id)
                                    .frame(width: 92, height: 92)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(store.theme.ink.opacity(0.10), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            if let onRemove {
                                Button {
                                    onRemove(id)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(store.theme.gold)
                                        .frame(width: 22, height: 22)
                                        .background(store.theme.dark, in: Circle())
                                        .overlay(Circle().stroke(store.theme.gold, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                                .offset(x: 6, y: -6)
                                .accessibilityLabel("Remove picture")
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
                .padding(.trailing, 8)
            }
            .sheet(item: Binding(
                get: { open.map { PhotoPreview.Item(id: $0) } },
                set: { open = $0?.id }
            )) { item in
                PhotoPreview(id: item.id)
                    .environmentObject(store)
            }
        }
    }
}

private struct PhotoPreview: View {
    struct Item: Identifiable { let id: String }
    @EnvironmentObject private var store: ReadingStore
    @Environment(\.dismiss) private var dismiss
    let id: String

    var body: some View {
        NavigationStack {
            Group {
                if let image = NotePhotos.load(id) {
                    ZoomableImage(image: image)
                } else {
                    Text("This picture is missing.")
                        .font(QuietFont.body(16))
                        .foregroundStyle(store.theme.mute)
                }
            }
            .background(store.theme.page)
            .navigationTitle("Picture")
            .navigationBarTitleDisplayMode(.inline)
            .quietBar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
    }
}

struct NotePhotoComposer: View {
    @EnvironmentObject private var store: ReadingStore
    @Binding var ids: [String]
    @Binding var created: [String]
    @State private var camera = false
    @State private var picker: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NotePhotoFilm(ids: ids) { id in
                ids.removeAll { $0 == id }
            }

            HStack(alignment: .center, spacing: 14) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(store.theme.gold)
                    .frame(width: 40, height: 40)
                    .background(store.theme.dark, in: Circle())
                    .overlay(Circle().stroke(store.theme.gold, lineWidth: 1))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Take a picture")
                        .font(QuietFont.display(18))
                        .foregroundStyle(store.theme.ink)
                    Text("A page, a place, a handwritten note.")
                        .font(QuietFont.small(13))
                        .foregroundStyle(store.theme.mute)
                }
            }

            HStack(spacing: 10) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    outlined("Camera") { camera = true }
                }
                PhotosPicker(selection: $picker, matching: .images) {
                    Text("Library")
                        .font(QuietFont.small(15))
                        .foregroundStyle(store.theme.gold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(store.theme.dark, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(store.theme.gold, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(store.theme.ink.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .fullScreenCover(isPresented: $camera) {
            CameraPicker { image in
                add(image)
            }
            .ignoresSafeArea()
        }
        .onChange(of: picker) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run { add(image) }
                }
                await MainActor.run { picker = nil }
            }
        }
    }

    private func outlined(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(QuietFont.small(15))
                .foregroundStyle(store.theme.gold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(store.theme.dark, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(store.theme.gold, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func add(_ image: UIImage) {
        if let id = NotePhotos.save(image) {
            ids.append(id)
            created.append(id)
        }
    }
}

struct NotePhotoThumb: View {
    let id: String

    var body: some View {
        if let image = NotePhotos.load(id) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Color.gray.opacity(0.2)
        }
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(onImage: onImage, dismiss: dismiss)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImage: (UIImage) -> Void
        let dismiss: DismissAction

        init(onImage: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onImage = onImage
            self.dismiss = dismiss
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImage(image)
            }
            dismiss()
        }
    }
}
