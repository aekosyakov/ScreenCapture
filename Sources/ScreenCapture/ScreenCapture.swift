import Foundation
import AVFoundation
import Cocoa

public
enum CaptureError: Error {
    case invalidScreen
    case invalidAudioDevice
    case couldNotAddScreen
    case couldNotAddMic
    case couldNotAddOutput
}

public final
class ScreenCapture: NSObject {

    private let session: AVCaptureSession
    private let output: AVCaptureVideoDataOutput
    private var activity: NSObjectProtocol?
    
    public var onStart: (() -> Void)?
    public var onFinish: (() -> Void)?
    public var onError: ((Error) -> Void)?
    public var onPause: (() -> Void)?
    public var onResume: (() -> Void)?
    public var onDataStream: ((Data) -> Void)?

    public let devices = Devices.self

    public
    init(
        framesPerSecond: Int = 60,
        cropRect: CGRect? = NSScreen.main?.frame,
        showCursor: Bool = true,
        highlightClicks: Bool = true,
        screenId: CGDirectDisplayID = .main,
        audioDevice: AVCaptureDevice? = .default(for: .audio),
        videoCodec: AVVideoCodecType? = nil
    ) throws {
        session = AVCaptureSession()
        
        let input = try AVCaptureScreenInput(displayID: screenId).unwrapOrThrow(CaptureError.invalidScreen)
        
        input.minFrameDuration = CMTime(videoFramesPerSecond: framesPerSecond)
        
        if let cropRect = cropRect {
            input.cropRect = cropRect
        }
        
        input.capturesCursor = showCursor
        input.capturesMouseClicks = highlightClicks
        
        if let audioDevice = audioDevice {
            if !audioDevice.hasMediaType(.audio) {
                throw CaptureError.invalidAudioDevice
            }
            
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)
            
            if session.canAddInput(audioInput) {
                session.addInput(audioInput)
            } else {
                throw CaptureError.couldNotAddMic
            }
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        } else {
            throw CaptureError.couldNotAddScreen
        }
        
        output = AVCaptureVideoDataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
        } else {
            throw CaptureError.couldNotAddOutput
        }
        super.init()
    }
    
    public
    func start() {
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer"))
        session.startRunning()
        onStart?()
    }
    
    public
    func stop() {
        session.stopRunning()
        onFinish?()
    }

}


extension ScreenCapture : AVCaptureVideoDataOutputSampleBufferDelegate {
    
    public
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        CVPixelBufferLockBaseAddress(imageBuffer,[])
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let cvBuff = CVPixelBufferGetBaseAddress(imageBuffer)
        CVPixelBufferUnlockBaseAddress(imageBuffer, []);
        guard let cvBuffer = cvBuff else {
            print("buff nil")
            return
        }
        let data = Data(bytes: cvBuffer, count: bytesPerRow * height)
        onDataStream?(data)
    }
    
}
