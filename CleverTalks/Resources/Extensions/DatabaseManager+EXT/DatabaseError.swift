//
//  DatabaseError.swift
//  CleverTalks
//
//  Created by Iryna V Betancourt on 2/23/21.
//

import Foundation

extension DatabaseManager {

    public enum DatabaseError: Error {
        case fetchFailure

        public var localizedDescription: String {
            switch self {
            case .fetchFailure:
                return "Error occured fetching data"
            }
        }
    }

}
