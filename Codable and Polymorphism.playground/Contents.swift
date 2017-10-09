//: Playground - noun: a place where people can play

import Cocoa

let url = URL(string: "https://itunes.apple.com/search?term=frozen&kind=all")!
let data = try! Data(contentsOf: url)
let jsonDecoder = JSONDecoder()

class SearchResult : Decodable {
    let wrapperType: String
    let kind: String
}

class SongResult : SearchResult {
    let trackName: String
    let artistName: String
    let trackNumber: Int
    let trackCount: Int
    let discNumber: Int
    
    enum CodingKeys : String, CodingKey {
        case trackName
        case artistName
        case trackNumber
        case trackCount
        case discNumber
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        trackName = try container.decode(String.self, forKey: .trackName)
        artistName = try container.decode(String.self, forKey: .artistName)
        trackNumber = try container.decode(Int.self, forKey: .trackNumber)
        trackCount = try container.decode(Int.self, forKey: .trackCount)
        discNumber = try container.decode(Int.self, forKey: .discNumber)
        try super.init(from: decoder)
    }
}

class MovieResult : SearchResult {
    let name: String
    let director: String
    let rating: String
    
    enum CodingKeys : String, CodingKey {
        case name = "trackName"
        case director = "artistName"
        case rating = "contentAdvisoryRating"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        director = try container.decode(String.self, forKey: .director)
        rating = try container.decode(String.self, forKey: .rating)
        try super.init(from: decoder)
    }
}

enum SearchResultWrapper : Decodable {
    case song(SongResult)
    case movie(MovieResult)
    
    var searchResult: SearchResult {
        switch self {
        case .song(let s): return s
        case .movie(let m): return m
        }
    }
    
    enum CodingKeys : String, CodingKey {
        case kind
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(String.self, forKey: .kind)
        switch kind {
        case "song":
            self = .song(try SongResult(from: decoder))
        case "feature-movie":
            self = .movie(try MovieResult(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unhandled kind: \(kind)")
        }
    }
}

struct SearchResponse : Decodable {
    let resultCount: Int
    let results: [SearchResult]
    
    enum CodingKeys : String, CodingKey {
        case resultCount
        case results
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        resultCount = try container.decode(Int.self, forKey: .resultCount)
  
        var results: [SearchResult] = []
        var resultsContainer = try container.nestedUnkeyedContainer(forKey: .results)
        while !resultsContainer.isAtEnd {
            let wrapper = try resultsContainer.decode(SearchResultWrapper.self)
            results.append(wrapper.searchResult)
        }
        self.results = results
    }
}



let result = try! jsonDecoder.decode(SearchResponse.self, from: data)

dump(result)
