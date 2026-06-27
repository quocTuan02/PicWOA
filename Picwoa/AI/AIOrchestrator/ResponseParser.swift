import Foundation

struct ResponseParser {

    static func parse(data: Data) throws -> AICoachingResponse {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String,
              let contentData = content.data(using: .utf8),
              let parsed = try JSONSerialization.jsonObject(with: contentData) as? [String: Any]
        else { throw OpenAIError.parseError }

        return try decode(from: parsed)
    }

    static func decode(from json: [String: Any]) throws -> AICoachingResponse {
        guard let mainCue = json["main_cue"] as? String else {
            throw OpenAIError.parseError
        }

        let recipeJson = json["editing_recipe"] as? [String: Any] ?? [:]
        let recipe = EditingRecipe(
            exposure:    (recipeJson["exposure"]    as? Double).map(Float.init) ?? 0,
            contrast:    (recipeJson["contrast"]    as? Double).map(Float.init) ?? 0,
            highlights:  (recipeJson["highlights"]  as? Double).map(Float.init) ?? 0,
            shadows:     (recipeJson["shadows"]     as? Double).map(Float.init) ?? 0,
            temperature: (recipeJson["temperature"] as? Double).map(Float.init) ?? 0,
            vibrance:    (recipeJson["vibrance"]    as? Double).map(Float.init) ?? 0
        )

        return AICoachingResponse(
            mainCue:            mainCue,
            secondaryCue:       json["secondary_cue"]     as? String,
            cameraInstruction:  json["camera_instruction"] as? String,
            score:              (json["score"] as? Int) ?? 3,
            feedback:           (json["feedback"] as? String) ?? "",
            editingRecipe:      recipe
        )
    }
}
