import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return req.view.render("index")
    }

    if #available(macOS 12, *) {
        app.post("send") { req async throws -> View in
            do {
                let input = try req.content.decode(Input.self)
                
                let clientResponse = try await req.client.post("https://api.nexmo.com/v1/messages") { req in
                    try req.content.encode(input, as: .json)
                    let auth = BasicAuthorization(
                        username: Environment.get("APIKEY")!,
                        password: Environment.get("APISECRET")!
                    )
                    req.headers.basicAuthorization = auth
                }
                let messageResponse = try clientResponse.content.decode(Response.self)
                
                return try await req.view.render(
                    "index",
                    ["messageId": "\(messageResponse.messageId)"]
                )
            }
        }
    } else {
        // Fallback on earlier versions
        print("You must you iOS 15")
    }
}

struct Input: Content {
    let to: String
    let text: String
    let from = "Swift"
    let channel = "sms"
    let messageType = "text"

    private enum CodingKeys: String, CodingKey {
        case to
        case text
        case from
        case channel
        case messageType = "message_type"
    }
}

struct Response: Content {
    let messageId: String
    
    private enum CodingKeys: String, CodingKey {
        case messageId = "message_uuid"
    }
}
