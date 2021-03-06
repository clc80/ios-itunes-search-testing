//
//  SearchResultController.swift
//  iTunes Search
//
//  Created by Spencer Curtis on 8/5/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation

protocol NetworkSessionProtocol {
    func fetch(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void)
}

// Production version of `NetworkSessionProtocol`
extension URLSession : NetworkSessionProtocol {
    func fetch(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        
        let dataTask = self.dataTask(with: request, completionHandler: completionHandler)

        dataTask.resume()
    }
}

// Testing version of 'Network Session Protocol'
class MockURLSession: NetworkSessionProtocol {
    
    let data: Data?
    let error: Error?
    init (data: Data?, error: Error?) {
        self.data = data
        self.error = error
    }
    
    func fetch(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        DispatchQueue.global().async {
            completionHandler(self.data, nil, self.error)
        }
    }
}
class SearchResultController {
    
    // escaping: It will be run later. It will happen after the function finishes. Will be asynchronously
    // A generic is a placeholder type, that way we can use any type in our code.
    
    enum PerformSearchError: Error {
        case requestURLIsNil
        case networkError(Error)
        case invalidStateNoErrorButNoDataEither
        case invalidJSON(Error)
        }
    
        // MARK: Properties
        let baseURL = URL(string: "https://itunes.apple.com/search")!
    
    
    func performSearch(for searchTerm: String, resultType: ResultType,
                       urlSession: NetworkSessionProtocol,
                       completion: @escaping (Result<[SearchResult], PerformSearchError>) -> Void) {
        
        // Preparing the parameters for our URL request.
        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        let parameters = ["term": searchTerm,
                          "entity": resultType.rawValue]
        
        // Compact Map -> Transforms the individual elements of a collection into some other element type while ignoring any optional that return a nil value
        // (Key, value)  -> (URL Query Item)
        let queryItems = parameters.compactMap { URLQueryItem(name: $0.key, value: $0.value) }
        urlComponents?.queryItems = queryItems
        
        // Prevent execution if requestURL is nil.
        guard let requestURL = urlComponents?.url else {
            completion(.failure(.requestURLIsNil))
            return
        }
        
        // 'requestURL' is not nil
        var request = URLRequest(url: requestURL)
        request.httpMethod = HTTPMethod.get.rawValue
        
        // Begin a network request to the iTunes API.
        urlSession.fetch(with: request) { (possibleData, _, possibleError) in
        
        //let dataTask = urlSession.dataTask(with: request) { (possibleData, _, possibleError) in
            
            // What queue are we in? We're in a Background Queue
            // We are making sure that there are no networking errors
            guard possibleError == nil else {
                completion(.failure(.networkError(possibleError!)))
                return
            }
            
            // We did receive data form iTunes API
            guard let data = possibleData else {
                completion(.failure(.invalidStateNoErrorButNoDataEither))
                return
            }
            
            do {
                // Decode the data we receied into a JSON
                let jsonDecoder = JSONDecoder()
                let searchResults = try jsonDecoder.decode(SearchResults.self, from: data)

                // We're finished
                completion(.success(searchResults.results))
            } catch {
                completion(.failure(.invalidJSON(error)))
            }
        }
    }
}
