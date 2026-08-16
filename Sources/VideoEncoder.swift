import AVFoundation

enum VideoEncoder {
    static func encode(source: URL, destination: URL, bitrate: Int) async throws {
        try? FileManager.default.removeItem(at: destination)
        let asset = AVURLAsset(url: source)
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else { throw ExportError.noVideoTrack }
        let reader = try AVAssetReader(asset: asset)
        let writer = try AVAssetWriter(outputURL: destination, fileType: .mp4)
        let size = try await videoTrack.load(.naturalSize)
        let transform = try await videoTrack.load(.preferredTransform)
        let estimatedFrameRate = max(1, try await videoTrack.load(.nominalFrameRate))
        let videoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
        reader.add(videoOutput)
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: abs(size.width), AVVideoHeightKey: abs(size.height),
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: bitrate, AVVideoExpectedSourceFrameRateKey: estimatedFrameRate, AVVideoMaxKeyFrameIntervalKey: Int(estimatedFrameRate * 2)]
        ])
        videoInput.transform = transform; videoInput.expectsMediaDataInRealTime = false; writer.add(videoInput)
        var audioPair: (AVAssetReaderOutput, AVAssetWriterInput)?
        if let audioTrack = try await asset.loadTracks(withMediaType: .audio).first {
            let audioOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: nil)
            reader.add(audioOutput)
            let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: nil)
            writer.add(audioInput)
            audioPair = (audioOutput, audioInput)
        }
        guard reader.startReading() else { throw reader.error ?? ExportError.couldNotStart }
        guard writer.startWriting() else { throw writer.error ?? ExportError.couldNotStart }
        writer.startSession(atSourceTime: .zero)
        if let (audioOutput, audioInput) = audioPair {
            pump(audioOutput, into: audioInput, queue: DispatchQueue(label: "audio.writer"))
        }
        pump(videoOutput, into: videoInput, queue: DispatchQueue(label: "video.writer"))
        await writer.finishWriting()
        if writer.status != .completed { throw writer.error ?? ExportError.failed }
    }
    private static func pump(_ output: AVAssetReaderOutput, into input: AVAssetWriterInput, queue: DispatchQueue) {
        input.requestMediaDataWhenReady(on: queue) {
            while input.isReadyForMoreMediaData {
                guard let sample = output.copyNextSampleBuffer() else { input.markAsFinished(); return }
                input.append(sample)
            }
        }
    }
    enum ExportError: LocalizedError { case noVideoTrack, couldNotStart, failed
        var errorDescription: String? { switch self { case .noVideoTrack: return "No video track was found."; case .couldNotStart: return "The export session could not start."; case .failed: return "The writer did not finish." } }
    }
}
