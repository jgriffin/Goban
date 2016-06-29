//
//  SGFFilesTests.swift
//  GobanSampleProject
//
//  Created by John on 5/7/16.
//  Copyright © 2016 Boris Emorine. All rights reserved.
//

import XCTest

class SGFFilesTests: XCParserTestBase {
    func contentsOfFileWithName(name: String) -> String?  {
        let bundle = NSBundle(forClass: self.dynamicType)
        guard let path = bundle.pathForResource(name, ofType: nil) else {
            return nil
        }
        return try! String(contentsOfFile: path)
    }

    typealias SGFPC = SGFParserCombinator
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testHeader() {
        let testString = "(;GM[1])"
        let results = testParseString(SGFPC.collectionParser(), testString)
        XCTAssertEqual(1, results.count)
    }

    func testLeeSodolHeader() {
        let testString = contentsOfFileWithName("LeeSedolHeader.sgf")!
        let results = testParseString(SGFPC.collectionParser(), testString)
        XCTAssertEqual(1, results.count)
    }
    
    func testLeeSedol() {
        let testString = contentsOfFileWithName("Lee-Sedol-vs-AlphaGo-Simplified.sgf")!
        let results = testParseString(SGFPC.collectionParser(), testString)
        XCTAssertEqual(1, results.count)
        
        let game: SGFP.GameTree? = results.first?.0.games.first
        XCTAssertNotNil(game)
        
        XCTAssertEqual(game?.fileFormat, 4)
        XCTAssertEqual(game?.application, "CGoban:3")
        XCTAssertEqual(game?.rules, "Chinese")
        XCTAssertEqual(game?.boardSize, 19)
        XCTAssertEqual(game?.komi, 7.5)
        XCTAssertEqual(game?.timeLimit, 7200)
        XCTAssertEqual(game?.overtime, "3x60 byo-yomi")
        XCTAssertEqual(game?.whiteName, "AlphaGo")
        XCTAssertEqual(game?.blackName, "Lee Sedol")
        XCTAssertEqual(game?.blackRank, "9d")
        XCTAssertEqual(game?.date?.timeIntervalSince1970, 1452326400.0)
        XCTAssertEqual(game?.eventName, "Google DeepMind Challenge Match")
        XCTAssertEqual(game?.round, "Game 1")
        XCTAssertEqual(game?.locationName, "Seoul, Korea")
        XCTAssertEqual(game?.whiteTeam, "Computer")
        XCTAssertEqual(game?.blackTeam, "Human")
        XCTAssertEqual(game?.source, "https://gogameguru.com/")
        XCTAssertEqual(game?.result, "W+Resign")
        XCTAssertEqual(game?.nodes.count, 9)
        
        let expectations = [[21],
                            [1, "B", "qd"],
                            [1, "W", "dd"],
                            [1, "B", "pq"],
                            [1, "W", "dp"],
                            [1, "B", "fc"],
                            [1, "W", "cf"],
                            [1, "B", "gh"],
                            [2, "W", "fh"]]
        
        for (index, node) in game!.nodes.enumerate() {
            XCTAssertEqual(node.properties.count, expectations[index][0])
            if index != 0 {
                let property = node.properties.first!
                XCTAssertEqual(property.identifier, expectations[index][1])
                XCTAssertEqual(property.values.first!.asString, expectations[index][2])
            }
        }
    }

    func testFF4ExampleSimplifiedFile() {
        let testString = contentsOfFileWithName("ff4_ex_simplified.sgf")!
        let results = testParseString(SGFPC.collectionParser(), testString)
        XCTAssertEqual(1, results.count)
    }

    func testFF4ExampleFile() {
        let testString = contentsOfFileWithName("ff4_ex.sgf")!
        let results = testParseString(SGFPC.collectionParser(), testString)
        XCTAssertEqual(1, results.count)
    }

}
