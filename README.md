# 📸 Photo Swiper

Photo Swiper is a native iOS photo-management app built with **SwiftUI**. It provides a Tinder-style interface for quickly reviewing photos from your camera roll, allowing users to swipe through images, mark unwanted photos for deletion, keep photos they want, and undo recent decisions.

The app was built to explore modern SwiftUI interfaces, gesture-driven interactions, and integration with Apple's Photos framework. (2026)

## ✨ Features

* 📷 **Photo Library Integration**
  Select multiple images directly from the device's photo library using `PhotosPicker`.

* 👈 **Swipe Left to Delete**
  Swipe a photo to the left to mark it for deletion.

* 👉 **Swipe Right to Keep**
  Swipe a photo to the right to keep it.

* ↩️ **Undo**
  Undo the most recent swipe and return to that photo.

* 🗑️ **Batch Deletion**
  Photos marked for deletion are queued and removed from the photo library together after confirmation.

* 🃏 **Stacked Photo Interface**
  Displays multiple photos in a layered card stack to provide a preview of upcoming images.

* 📊 **Session Progress**
  Shows the user's current position within the photo review session.

* ✅ **Session Completion**
  Automatically finishes the review once all selected photos have been processed.

* 🔐 **Photo Library Permissions**
  Handles photo library authorization before attempting to delete assets.

## 🛠️ Tech Stack

* **Swift**
* **SwiftUI**
* **PhotosUI**
* **Photos Framework**
* **iOS**

## 🧠 How It Works

Photos are selected from the user's camera roll using Apple's `PhotosPicker`. Each selected image is loaded into memory and represented by a `PhotoItem` model containing the image, picker item, and associated photo-library asset identifier.

The main interface maintains a stack of photo cards. The currently displayed card responds to a `DragGesture`, with the horizontal translation determining the user's action:

```text
          Photo Card
              │
        ┌─────┴─────┐
        │           │
     Swipe Left   Swipe Right
        │           │
        ▼           ▼
     Delete        Keep
        │           │
        └─────┬─────┘
              ▼
        Next Photo
```

Photos marked for deletion are stored in a deletion queue rather than being immediately removed. This allows the user to review their selections before confirming the deletion.

When deletion is confirmed, the app uses `PHPhotoLibrary` and `PHAssetChangeRequest` to remove the corresponding assets from the device's photo library.

## 📱 User Flow

1. Select photos from the camera roll.
2. Review photos one at a time.
3. Swipe **left** to mark a photo for deletion.
4. Swipe **right** to keep a photo.
5. Use **Undo** to reverse the most recent decision.
6. Finish the session once all photos have been reviewed.
7. Confirm the batch deletion.
8. Deleted photos are removed from the photo library.

## 🏗️ Project Structure

```text
photo_swiper/
├── ContentView.swift
└── ...
```

### `ContentView`

Contains the primary application interface and state management, including:

* Photo selection
* Photo stack rendering
* Swipe gestures
* Undo functionality
* Deletion queue management
* Photo library authorization
* Batch deletion
* Session completion

### `PhotoItem`

Represents an individual photo being reviewed.

Stores:

* `UIImage`
* `PhotosPickerItem`
* Photo library asset identifier
* Unique identifier for application state management

### `SwipeAction`

Records the user's decision for a photo:

* `kept`
* `deleted`

This history enables the undo functionality.

## 🎯 What I Learned

This project provided hands-on experience with:

* Building gesture-driven interfaces with **SwiftUI**
* Managing application state using SwiftUI property wrappers
* Working with `PhotosPicker` and `PhotosPickerItem`
* Integrating with the iOS Photos framework
* Handling asynchronous image loading
* Managing photo-library permissions
* Performing batch asset operations with `PHPhotoLibrary`
* Designing undoable user interactions
* Creating layered card-based UI components

## 🚀 Future Improvements

Potential improvements include:

* [ ] Add animated swipe indicators for **Keep** and **Delete**
* [ ] Add haptic feedback during swipe interactions
* [ ] Add filtering by date, album, or media type
* [ ] Improve memory management for large photo selections
* [ ] Add support for videos
* [ ] Add statistics for each review session
* [ ] Add a dedicated review screen for queued deletions
* [ ] Add accessibility improvements for gesture-free navigation

## 📄 License

This project is available for educational and portfolio purposes.
