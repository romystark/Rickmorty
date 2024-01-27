import Foundation
import Combine

struct Client {
    static let rickAndMorty = Client("https://rickandmortyapi.com")
    let session = URLSession.shared
    let baseUrl: String
    private let contentType: String

    enum NetworkError: Error {
        case conection
        case invalidRequest
        case invalidResponse
        case client
        case server
    }

    init(_ baseUrl: String, contentType: String = "application/json") {
        self.baseUrl = baseUrl
        self.contentType = contentType
    }

    typealias requesHandler = ((Data?) -> Void)
    typealias errorHandler = ((NetworkError) -> Void)

    func get(_ path: String, query: [String: String] = [:], success: requesHandler?, failure: errorHandler? = nil) {
        request(method: "GET", path: path, query: query, success: success, failure: failure)
    }

    func get(_ path: String, query: [String: String] = [:]) async throws -> Result<Data?, NetworkError> {
        return try await request(method: "GET", path: path, query: query)
    }

    func getPublisher(_ path: String, query: [String: String] = [:]) -> AnyPublisher<Data?, NetworkError> {
        return requestPublisher(method: "GET", path: path, query: query)
    }

    // Request via GCD using response handlers
    func request(method: String, path: String, query: [String: String] = [:], body: Data? = nil, success: requesHandler?, failure: errorHandler? = nil) {
        guard let request = buildRequest(method: method, path: path, query: query, body: body) else {
            failure?(NetworkError.invalidRequest)
            return
        }
        #if DEBUG
        debugPrint(request)
        #endif

        let task = session.dataTask(with: request) { data, response, error in
            if let err = error {
                #if DEBUG
                debugPrint(err)
                #endif
                failure?(NetworkError.conection)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                failure?(NetworkError.invalidResponse)
                return
            }

            let status = StatusCode(rawValue: httpResponse.statusCode)
            #if DEBUG
            print("Status: \(httpResponse.statusCode)")
            // debugPrint(httpResponse)
            #endif
            switch status {
            case .success:
                success?(data)
            case .clientError:
                failure?(.client)
            case .serverError:
                failure?(.server)
            default:
                failure?(.invalidResponse)
            }
        }
        task.resume()
    }

    // Request via async/await with Result type
    func request(method: String, path: String, query: [String: String] = [:], body: Data? = nil) async throws -> Result<Data?, NetworkError> {
        guard let request = buildRequest(method: method, path: path, query: query, body: body) else {
            return .failure(NetworkError.invalidRequest)
        }
        #if DEBUG
        debugPrint(request)
        #endif
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            return .failure(.invalidResponse)
        }

        let status = StatusCode(rawValue: httpResponse.statusCode)
        #if DEBUG
        print("Status: \(httpResponse.statusCode)")
        // debugPrint(httpResponse)
        #endif
        switch status {
        case .success:
            return .success(data)
        case .clientError:
            return .failure(.client)
        case .serverError:
            return .failure(.server)
        default:
            return .failure(.invalidResponse)
        }
    }

    func requestPublisher(method: String, path: String, query: [String: String] = [:], body: Data? = nil) -> AnyPublisher<Data?, NetworkError> {
        guard let request = buildRequest(method: method, path: path, query: query, body: body) else {
            return Fail(error: NetworkError.invalidRequest).eraseToAnyPublisher()
        }
        return session
            .dataTaskPublisher(for: request)
            .tryMap { (data, response) -> Data? in
                let httpResponse = response as! HTTPURLResponse
                let status = StatusCode(rawValue: httpResponse.statusCode)
                #if DEBUG
                print("Status: \(httpResponse.statusCode)")
                debugPrint(httpResponse)
                #endif
                switch status {
                case .success: break
                case .clientError:
                    throw NetworkError.client
                case .serverError:
                    throw NetworkError.server
                default:
                    throw NetworkError.invalidResponse
                }
                return data
            }
            .mapError { error -> NetworkError in
                switch error {
                case NetworkError.client:
                    return .client
                case NetworkError.server:
                    return .server
                default:
                    return NetworkError.invalidResponse
                }
            }
            .eraseToAnyPublisher()
    }

    private func buildRequest(method: String, path: String, query: [String: String] = [:], body: Data?) -> URLRequest? {
        guard var urlComp = URLComponents(string: baseUrl) else { return nil }
        urlComp.path = path
        urlComp.queryItems = query.map { (key, value) in
            URLQueryItem(name: key, value: value)
        }

        guard let url = urlComp.url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        #if DEBUG
        debugPrint(request)
        #endif
        return request
    }
}

