import Foundation

struct EditingRecipe: Sendable {
    let exposure: Float    // -1.0 to 1.0
    let contrast: Float    // -100 to 100
    let highlights: Float  // -100 to 100
    let shadows: Float     // -100 to 100
    let temperature: Float // -100 to 100
    let vibrance: Float    // -100 to 100

    static let neutral = EditingRecipe(
        exposure: 0, contrast: 0, highlights: 0,
        shadows: 0, temperature: 0, vibrance: 0
    )
}
