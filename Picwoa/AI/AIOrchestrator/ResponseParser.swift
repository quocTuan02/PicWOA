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

        let overlay = (json["overlay"] as? [[String: Any]] ?? []).compactMap { item -> OverlayCue? in
            guard let part = item["part"] as? String,
                  let direction = item["direction"] as? String else { return nil }
            return OverlayCue(part: part, type: item["type"] as? String ?? "arrow", direction: direction)
        }

        // The LLM may return score as 4, 4.0, or "4" — accept all three, default to 3.
        let score = (json["score"] as? Int)
            ?? (json["score"] as? Double).map(Int.init)
            ?? (json["score"] as? String).flatMap(Int.init)
            ?? 3

        return AICoachingResponse(
            mainCue:            mainCue,
            secondaryCue:       json["secondary_cue"]     as? String,
            cameraInstruction:  json["camera_instruction"] as? String,
            score:              score,
            feedback:           (json["feedback"] as? String) ?? "",
            editingRecipe:      recipe,
            overlay:            overlay
        )
    }
}
