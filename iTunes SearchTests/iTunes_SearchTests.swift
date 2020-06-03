//
//  iTunes_SearchTests.swift
//  iTunes SearchTests
//
//  Created by Claudia Contreras on 6/2/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import XCTest
@testable import iTunes_Search

class iTunes_SearchTests: XCTestCase {

    func testSucessfulSearchResults() {
        
        let searchResultsController = SearchResultController()
        
        let expectation = self.expectation(description: "Waiting for iTunes API")
        searchResultsController.performSearch(for: "Candy Crush", resultType: .software) { (result) in
            switch result {
            case .success(let searchResultsArray):
                XCTAssert(searchResultsArray.count > 0)
               break
            case .failure(let error):
                XCTFail("The iTunes API failed \(error)")
            }
            expectation.fulfill()
        }
         wait(for: [expectation], timeout: 5)
    }

}
