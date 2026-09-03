//
//  ContentView.swift
//  photo_swiper
//
//  Created by Ajay Arora on 2026-09-03.
//
import SwiftUI

import PhotosUI

import Photos

struct ContentView: View {

    @State private var selectedItems: [PhotosPickerItem] = []

    @State private var photos: [PhotoItem] = []

    @State private var currentIndex = 0

    @State private var deletionQueue: [UUID] = []

    @State private var history: [SwipeAction] = []

    @State private var dragOffset: CGSize = .zero

    @State private var showingDeleteConfirmation = false

    var body: some View {

        NavigationStack {

            VStack(spacing: 0) {

                if photos.isEmpty {

                    emptyState

                } else if currentIndex >= photos.count {

                    finishedState

                } else {

                    photoStack

                    controls

                }

            }

            .navigationTitle("Photo Swiper")

            .navigationBarTitleDisplayMode(.inline)

            .alert(

                "Delete Photos?",

                isPresented: $showingDeleteConfirmation

            ) {

                Button("Cancel", role: .cancel) {}

                Button("Delete", role: .destructive) {

                    deletePhotos()

                }

            } message: {

                Text(

                    "You have \(deletionQueue.count) photo\(deletionQueue.count == 1 ? "" : "s") marked for deletion."

                )

            }

        }

    }

    // MARK: - Empty State

    private var emptyState: some View {

        VStack(spacing: 20) {

            Spacer()

            Image(systemName: "photo.on.rectangle.angled")

                .font(.system(size: 70))

                .foregroundStyle(.secondary)

            Text("No Photos")

                .font(.title)

                .fontWeight(.semibold)

            Text("Add photos from your camera roll to start swiping.")

                .multilineTextAlignment(.center)

                .foregroundStyle(.secondary)

                .padding(.horizontal, 40)

            photoPickerButton

            Spacer()

        }

        .padding()

    }

    // MARK: - Photo Picker

    private var photoPickerButton: some View {

        PhotosPicker(

            selection: $selectedItems,

            maxSelectionCount: nil,

            matching: .images

        ) {

            Label("Add Photos", systemImage: "photo.badge.plus")

                .font(.headline)

                .foregroundStyle(.white)

                .frame(maxWidth: 280)

                .padding()

                .background(Color.blue)

                .clipShape(RoundedRectangle(cornerRadius: 14))

        }

        .onChange(of: selectedItems) {

            Task {

                await loadSelectedPhotos()

            }

        }

    }

    // MARK: - Photo Stack

    private var photoStack: some View {

        GeometryReader { geometry in

            ZStack {

                // Third photo

                if currentIndex + 2 < photos.count {

                    photoCard(photos[currentIndex + 2])

                        .scaleEffect(0.90)

                        .offset(y: 28)

                }

                // Second photo

                if currentIndex + 1 < photos.count {

                    photoCard(photos[currentIndex + 1])

                        .scaleEffect(0.95)

                        .offset(y: 14)

                }

                // Current photo

                photoCard(photos[currentIndex])

                    .offset(dragOffset)

                    .rotationEffect(

                        .degrees(Double(dragOffset.width / 20))

                    )

                    .gesture(

                        DragGesture()

                            .onChanged { value in

                                dragOffset = value.translation

                            }

                            .onEnded { value in

                                handleSwipe(value.translation)

                            }

                    )

            }

            .frame(

                width: geometry.size.width,

                height: geometry.size.height

            )

            .padding(.horizontal, 20)

        }

    }

    private func photoCard(_ photo: PhotoItem) -> some View {

        Image(uiImage: photo.image)

            .resizable()

            .scaledToFit()

            .frame(maxWidth: .infinity, maxHeight: .infinity)

            .background(Color(.systemGray6))

            .clipShape(RoundedRectangle(cornerRadius: 18))

            .shadow(

                color: .black.opacity(0.2),

                radius: 10,

                y: 5

            )

    }

    // MARK: - Controls

    private var controls: some View {

        VStack(spacing: 12) {

            Text("\(currentIndex + 1) of \(photos.count)")

                .font(.caption)

                .foregroundStyle(.secondary)

            HStack(spacing: 10) {

                Button {

                    undoLastSwipe()

                } label: {

                    Label("Undo", systemImage: "arrow.uturn.backward")

                        .frame(maxWidth: .infinity)

                }

                .buttonStyle(.bordered)

                .disabled(history.isEmpty)

                PhotosPicker(

                    selection: $selectedItems,

                    maxSelectionCount: nil,

                    matching: .images

                ) {

                    Label("Add Photos", systemImage: "plus")

                        .frame(maxWidth: .infinity)

                }

                .buttonStyle(.bordered)

                .onChange(of: selectedItems) {

                    Task {

                        await loadSelectedPhotos()

                    }

                }

                Button {

                    finishSession()

                } label: {

                    Label("Finish", systemImage: "checkmark")

                        .frame(maxWidth: .infinity)

                }

                .buttonStyle(.borderedProminent)

                .disabled(deletionQueue.isEmpty)

            }

        }

        .padding(.horizontal)

        .padding(.top, 10)

        .padding(.bottom, 12)

    }

    // MARK: - Swipe Handling

    private func handleSwipe(_ translation: CGSize) {

        let threshold: CGFloat = 120

        if translation.width < -threshold {

            withAnimation(.easeIn(duration: 0.2)) {

                dragOffset = CGSize(

                    width: -1000,

                    height: translation.height

                )

            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {

                markCurrentPhotoForDeletion()

            }

        } else if translation.width > threshold {

            withAnimation(.easeIn(duration: 0.2)) {

                dragOffset = CGSize(

                    width: 1000,

                    height: translation.height

                )

            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {

                keepCurrentPhoto()

            }

        } else {

            withAnimation(.spring()) {

                dragOffset = .zero

            }

        }

    }

    private func markCurrentPhotoForDeletion() {

        guard currentIndex < photos.count else {

            return

        }

        let photo = photos[currentIndex]

        deletionQueue.append(photo.id)

        history.append(

            SwipeAction(

                photoID: photo.id,

                action: .deleted

            )

        )

        currentIndex += 1

        dragOffset = .zero

        if currentIndex >= photos.count {

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {

                finishSession()

            }

        }

    }

    private func keepCurrentPhoto() {

        guard currentIndex < photos.count else {

            return

        }

        history.append(

            SwipeAction(

                photoID: photos[currentIndex].id,

                action: .kept

            )

        )

        currentIndex += 1

        dragOffset = .zero

        if currentIndex >= photos.count && !deletionQueue.isEmpty {

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {

                finishSession()

            }

        }

    }

    // MARK: - Undo

    private func undoLastSwipe() {

        guard let lastAction = history.popLast() else {

            return

        }

        guard let index = photos.firstIndex(where: {

            $0.id == lastAction.photoID

        }) else {

            return

        }

        currentIndex = index

        if lastAction.action == .deleted {

            deletionQueue.removeAll {

                $0 == lastAction.photoID

            }

        }

        dragOffset = .zero

    }

    // MARK: - Finish

    private func finishSession() {

        guard !deletionQueue.isEmpty else {

            return

        }

        showingDeleteConfirmation = true

    }

    private func deletePhotos() {

        let idsToDelete = Set(deletionQueue)

        let assetIdentifiers = photos

            .filter { idsToDelete.contains($0.id) }

            .compactMap { $0.assetIdentifier }

        guard !assetIdentifiers.isEmpty else {

            print("❌ No asset identifiers found.")

            return

        }

        let authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        if authorizationStatus == .notDetermined {

            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in

                DispatchQueue.main.async {

                    if status == .authorized || status == .limited {

                        deletePhotos()

                    } else {

                        print("❌ Photo library permission denied.")

                    }

                }

            }

            return

        }

        guard authorizationStatus == .authorized ||

              authorizationStatus == .limited else {

            print("❌ Photo library does not have write permission.")

            return

        }

        let assets = PHAsset.fetchAssets(

            withLocalIdentifiers: assetIdentifiers,

            options: nil

        )

        guard assets.count > 0 else {

            print("❌ Could not find matching PHAssets.")

            print("Identifiers:", assetIdentifiers)

            return

        }

        print("🗑️ Attempting to delete \(assets.count) photo(s)...")

        PHPhotoLibrary.shared().performChanges({

            PHAssetChangeRequest.deleteAssets(assets)

        }) { success, error in

            DispatchQueue.main.async {

                if success {

                    print("✅ Photos deleted successfully.")

                    photos.removeAll {

                        idsToDelete.contains($0.id)

                    }

                    deletionQueue.removeAll()

                    history.removeAll()

                    currentIndex = 0

                    dragOffset = .zero

                } else {

                    print(

                        "❌ Failed to delete photos:",

                        error?.localizedDescription ?? "Unknown error"

                    )

                }

            }

        }

    }

    // MARK: - Finished State

    private var finishedState: some View {

        VStack(spacing: 20) {

            Spacer()

            Image(systemName: "checkmark.circle.fill")

                .font(.system(size: 70))

                .foregroundStyle(.green)

            Text("Session Complete")

                .font(.title)

                .fontWeight(.semibold)

            Text("You've reviewed all of the photos.")

                .foregroundStyle(.secondary)

            PhotosPicker(

                selection: $selectedItems,

                maxSelectionCount: nil,

                matching: .images

            ) {

                Label("Add More Photos", systemImage: "photo.badge.plus")

                    .font(.headline)

                    .foregroundStyle(.white)

                    .frame(maxWidth: 280)

                    .padding()

                    .background(Color.blue)

                    .clipShape(RoundedRectangle(cornerRadius: 14))

            }

            .onChange(of: selectedItems) {

                Task {

                    await loadSelectedPhotos()

                }

            }

            Spacer()

        }

        .padding()

    }

    // MARK: - Loading

    private func assetIdentifier(for item: PhotosPickerItem) -> String? {

        item.itemIdentifier

    }

    @MainActor

    private func loadSelectedPhotos() async {

        var newPhotos: [PhotoItem] = []

        for item in selectedItems {

            guard let data = try? await item.loadTransferable(type: Data.self),

                  let image = UIImage(data: data) else {

                continue

            }

            newPhotos.append(

                PhotoItem(

                    image: image,

                    pickerItem: item,

                    assetIdentifier: item.itemIdentifier

                )

            )

        }

        photos.append(contentsOf: newPhotos)

        selectedItems.removeAll()

    }

}

// MARK: - Photo Model

struct PhotoItem: Identifiable {

let id = UUID()

let image: UIImage

let pickerItem: PhotosPickerItem

    let assetIdentifier: String?

}

// MARK: - Swipe Action

struct SwipeAction {

let photoID: UUID

enum Action {

    case kept

    case deleted

}

let action: Action

}

#Preview {

ContentView()

}
