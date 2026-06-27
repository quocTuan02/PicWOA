import CoreImage
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
        colorControls.contrast = 1.0 + (recipe.contrast / 100.0)
        colorControls.brightness = 0
        colorControls.saturation = 1.0 + (recipe.vibrance / 200.0)
        output = colorControls.outputImage ?? output

        // Temperature
        let tempFilter = CIFilter.temperatureAndTint()
        tempFilter.inputImage = output
        tempFilter.neutral = CIVector(x: 6500 + CGFloat(recipe.temperature * 20), y: 0)
        output = tempFilter.outputImage ?? output

        // Highlights & Shadows
        let highlightFilter = CIFilter.highlightShadowAdjust()
        highlightFilter.inputImage = output
        highlightFilter.highlightAmount = 1.0 + (recipe.highlights / 100.0)
        highlightFilter.shadowAmount = 1.0 + (recipe.shadows / 100.0)
        output = highlightFilter.outputImage ?? output

        guard let cgImage = context.createCGImage(output, from: output.extent) else { return image }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
