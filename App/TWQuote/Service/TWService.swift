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
    
    var baseURL: URL {
        return URL(string: "https://wise.com/gateway/v3/comparisons")!
    }
}

struct TWService {
    let environment: Environment
    
    init(environment: Environment = TWServiceEnvironment.production) {
        self.environment = environment
    }

    func fetchQuote(sourceCurrency: TWCurrency, targetCurrency: TWCurrency, amount: Int, completion: @escaping (TWResponse?) -> ()) {
        let sessionConfig = URLSessionConfiguration.default
        
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        let URLParams = [
            "sendAmount": String(amount),
            "sourceCurrency": sourceCurrency.rawValue,
            "targetCurrency": targetCurrency.rawValue,
        ]
        guard let URL = environment.baseURL.appendingQueryParameters(URLParams) else {
            completion(nil)
            return
        }
        var request = URLRequest(url: URL)
        request.httpMethod = "GET"
        

        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if (error == nil) {
                if let data = data {
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        let twResponse = try decoder.decode(TWResponse.self, from: data)
                        completion(twResponse)
                    } catch {
                        print("Error \(error)")
                        completion(nil)
                    }
                }
            }
            else {
                print("URL Session Task Failed: %@", error!.localizedDescription);
                completion(nil)
            }
        })
        task.resume()
        session.finishTasksAndInvalidate()
    }
}

extension URL {
    func appendingQueryParameters(_ parametersDictionary : Dictionary<String, String>) -> URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        let items = components?.queryItems ?? []
        components?.queryItems = items + parametersDictionary.map { (key, value) in URLQueryItem(name: key, value: value) }
        return components?.url
    }
}
