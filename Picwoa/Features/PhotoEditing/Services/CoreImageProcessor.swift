@preconcurrency import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

struct CoreImageProcessor: ImageProcessor {

    private let context = CIContext()

    func apply(recipe: EditingRecipe, to image: UIImage) async -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }

        var output = ciImage

        // Exposure
        let exposureFilter = CIFilter.exposureAdjust()
        exposureFilter.inputImage = output
        exposureFilter.ev = recipe.exposure
        output = exposureFilter.outputImage ?? output

        // Contrast & Highlights & Shadows (via Tone Curve)
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = output
        colorControls.contrast = CGFloat(clamp(1.0 + (recipe.contrast / 250.0), min: 0.85, max: 1.25))
        colorControls.brightness = 0
        colorControls.saturation = CGFloat(clamp(1.0 + (recipe.vibrance / 300.0), min: 0.9, max: 1.2))
        output = colorControls.outputImage ?? output

        // Temperature
        let tempFilter = CIFilter.temperatureAndTint()
        tempFilter.inputImage = output
        tempFilter.neutral = CIVector(x: 6500 + CGFloat(clamp(recipe.temperature * 10, min: -600, max: 600)), y: 0)
        output = tempFilter.outputImage ?? output

        // Highlights & Shadows
        let highlightFilter = CIFilter.highlightShadowAdjust()
        highlightFilter.inputImage = output
        highlightFilter.highlightAmount = CGFloat(clamp(1.0 + (recipe.highlights / 300.0), min: 0.75, max: 1.15))
        highlightFilter.shadowAmount = CGFloat(clamp(recipe.shadows / 250.0, min: -0.25, max: 0.35))
        output = highlightFilter.outputImage ?? output

        guard let cgImage = context.createCGImage(output, from: output.extent) else { return image }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    private func clamp(_ value: Float, min lowerBound: Float, max upperBound: Float) -> Float {
        min(max(value, lowerBound), upperBound)
    }
}
