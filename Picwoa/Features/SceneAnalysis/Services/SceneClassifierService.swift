import AVFoundation
import CoreImage

struct SceneClassifierService {

    func classify(_ sampleBuffer: CMSampleBuffer) -> SceneContext {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return .unknown
        }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let avgBrightness = averageBrightness(of: ciImage)

        // Heuristic: outdoor scenes tend to be brighter
        // TODO: Dev B — replace with CoreML classifier for better accuracy
        return avgBrightness > 0.4 ? .outdoor : .indoor
    }

    private func averageBrightness(of image: CIImage) -> Float {
        let filter = CIFilter.areaAverage()
        filter.inputImage = image
        filter.extent = image.extent

        guard let output = filter.outputImage else { return 0.5 }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let ctx = CIContext()
        ctx.render(output, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        let r = Float(bitmap[0]) / 255
        let g = Float(bitmap[1]) / 255
        let b = Float(bitmap[2]) / 255
        return (r * 0.299 + g * 0.587 + b * 0.114)
    }
}
