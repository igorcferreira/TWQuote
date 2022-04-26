//
//  TWService.swift
//  TWQuote
//
//  Created by Fernando Bunn on 03/05/2019.
//  Copyright © 2019 Fernando Bunn. All rights reserved.
//

import Foundation

struct TWResponse: Codable {
    let providers: [Provider]
    var wiseQuote: Quote? {
        guard let wise = providers.filter({ $0.alias == "wise" }).first else { return nil }
        return wise.quotes.first
    }
}

struct Provider: Codable {
    let id: Int
    let alias: String
    let name: String
    let quotes: [Quote]
}

struct Quote: Codable {
    let rate: Decimal
    let fee: Decimal
    let receivedAmount: Decimal
}

enum TWCurrency: String, CaseIterable {
    case BRL = "BRL"
    case EUR = "EUR"
    case USD = "USD"
    case GBP = "GBP"
}

protocol Environment {
    var baseURL: URL { get }
}

enum TWServiceEnvironment: Environment {
    case production
    var baseURL: URL { Constants.urls.twServerURL }
}

enum ServiceError: Error {
    case invalidURL
    case requestError(code: URLError.Code)
}

struct TWService {
    let environment: Environment
    
    init(environment: Environment = TWServiceEnvironment.production) {
        self.environment = environment
    }

    func fetchQuote(sourceCurrency: TWCurrency, targetCurrency: TWCurrency, amount: Int) async throws -> TWResponse {
        let sessionConfig = URLSessionConfiguration.default
        
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        let URLParams = [
            "sendAmount": String(amount),
            "sourceCurrency": sourceCurrency.rawValue,
            "targetCurrency": targetCurrency.rawValue,
        ]
        guard let URL = environment.baseURL.appendingQueryParameters(URLParams) else {
            throw ServiceError.invalidURL
        }
        var request = URLRequest(url: URL)
        request.httpMethod = "GET"
        
        request.printCurl()
        let (data, response) = try await session.data(for: request)
        guard response.isSuccess else {
            throw ServiceError.requestError(code: response.code)
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(TWResponse.self, from: data)
    }
}

extension URLResponse {
    var isSuccess: Bool {
        guard let httpResponse = self as? HTTPURLResponse else {
            return false
        }
        return 200..<300 ~= httpResponse.statusCode
    }
    var code: URLError.Code {
        if let httpResponse = self as? HTTPURLResponse {
            return URLError.Code(rawValue: httpResponse.statusCode)
        } else {
            return URLError.Code.badServerResponse
        }
    }
}

extension URLRequest {
    func printCurl() {
        #if DEBUG
        guard let url = self.url, let method = self.httpMethod else {
            return
        }
        var components = ["curl -i"]
        components.append("-X \(method)")

        allHTTPHeaderFields?.forEach { (key, value) in
            components.append("-H '\(key): \(value)'")
        }

        if let data = httpBody, let body = String(data: data, encoding: .utf8) {
            components.append("-d '\(body)'")
        }

        components.append("\"\(url.absoluteString)\"")
        print("\(components.joined(separator: " \\\n\t"))")
        #endif
    }
}

extension URL {
    func appendingQueryParameters(_ parametersDictionary : Dictionary<String, String>) -> URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        let items = components?.queryItems ?? []
        components?.queryItems = items + parametersDictionary.sorted(by: { $0.key < $1.key }).map { (key, value) in URLQueryItem(name: key, value: value) }
        return components?.url
    }
}
