import SwiftUI
import PhotosUI
import AVFoundation

struct ContentView: View {
    @State private var pickerItem: PhotosPickerItem?
    @State private var sourceURL: URL?
    @State private var bitrateMbps = 30.0
    @State private var exporting = false
    @State private var status = "Choose a video to begin."
    @State private var outputURL: URL?

    var body: some View {
        NavigationStack {
            Form {
                Section("Source video") {
                    PhotosPicker(selection: $pickerItem, matching: .videos) {
                        Label(sourceURL == nil ? "Choose Video" : "Choose Another Video", systemImage: "video.badge.plus")
                    }
                    if let sourceURL { Text(sourceURL.lastPathComponent).lineLimit(1) }
                }
                Section("Output bitrate") {
                    HStack { Text("\(bitrateMbps, specifier: "%.0f") Mbps"); Spacer(); Text("Higher creates a larger file") .foregroundStyle(.secondary) }
                    Slider(value: $bitrateMbps, in: 5...100, step: 1)
                    Text("This re-encodes the selected video. It cannot restore detail lost in the original Alight Motion export, but it gives the new file the selected encoding bitrate.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section {
                    Button(action: beginExport) {
                        Label(exporting ? "Exporting…" : "Export High-Bitrate Video", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }.disabled(sourceURL == nil || exporting)
                }
                Section("Status") {
                    Text(status)
                    if let outputURL {
                        ShareLink(item: outputURL) { Label("Save or Share Export", systemImage: "square.and.arrow.up") }
                    }
                }
            }
            .navigationTitle("Zoron Exporter")
            .onChange(of: pickerItem) { item in load(item) }
        }
    }

    private func load(_ item: PhotosPickerItem?) {
        guard let item else { return }
        status = "Loading video…"
        Task {
            do {
                guard let movie = try await item.loadTransferable(type: MovieFile.self) else { return }
                let destination = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(movie.url.pathExtension)
                try FileManager.default.copyItem(at: movie.url, to: destination)
                await MainActor.run { sourceURL = destination; status = "Ready to export."; outputURL = nil }
            } catch { await MainActor.run { status = "Could not load video: \(error.localizedDescription)" } }
        }
    }

    private func beginExport() {
        guard let sourceURL else { return }
        exporting = true; outputURL = nil; status = "Encoding at \(Int(bitrateMbps)) Mbps…"
        let output = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Zoron-\(Int(Date().timeIntervalSince1970)).mp4")
        Task {
            do {
                try await VideoEncoder.encode(source: sourceURL, destination: output, bitrate: Int(bitrateMbps * 1_000_000))
                await MainActor.run { outputURL = output; status = "Done. Use Save or Share Export below."; exporting = false }
            } catch { await MainActor.run { status = "Export failed: \(error.localizedDescription)"; exporting = false } }
        }
    }
}
