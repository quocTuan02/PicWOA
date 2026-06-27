import UIKit

protocol ImageProcessor: Sendable {
    func apply(recipe: EditingRecipe, to image: UIImage) async -> UIImage
}
