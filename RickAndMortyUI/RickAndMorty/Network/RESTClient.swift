import Foundation
import Combine

struct RESTClient<T: Codable> {
    let client: Client
    let decoder: JSONDecoder = {
        var dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase
        return dec
    }()

    init(client: Client) {
        self.client = client
    }

    typealias successHandler = ((T) -> Void)

    func show(_ path: String, page: Int = 1, success: @escaping successHandler) {
        client.get(path, query: ["page": "\(page)"]) { data in
            guard let data = data else { return }

            do {
                let json = try decoder.decode(T.self, from: data)
                DispatchQueue.main.async { success(json) }
            } catch let err {
                #if DEBUG
                debugPrint(err)
                #endif
            }
        }
    }

    func show(path: String, page: Int = 1) async throws -> T? {
        let response = try await client.get(path, query: ["page": "\(page)"])
        switch response {
        case .success(let data):
            guard let data = data else { return nil }
            let json = try decoder.decode(T.self, from: data)
            return json
        case .failure(let error):
            debugPrint(error)
            return nil
        }
    }

    func showPublisher(path: String, page: Int = 1) -> AnyPublisher<T?, Error> {
        return client.getPublisher(path, query: ["page": "\(page)"])
                 .tryMap { data in
                     guard let data = data else { return nil }
                     return try decoder.decode(T.self, from: data)
                 }
                 .eraseToAnyPublisher()
    }
}
