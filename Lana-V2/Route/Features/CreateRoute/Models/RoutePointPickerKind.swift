//
//  RoutePointPickerKind.swift
//  Lana-V2
//

enum RoutePointPickerKind: String, Identifiable {
    case start
    case finish

    var id: String { rawValue }

    var title: String {
        switch self {
        case .start:
            return "Choose Start Point"
        case .finish:
            return "Choose Finish Point"
        }
    }

    var fieldTitle: String {
        switch self {
        case .start:
            return "Start Point"
        case .finish:
            return "Finish Point"
        }
    }

    var placeholder: String {
        switch self {
        case .start:
            return "Choose where the ride starts"
        case .finish:
            return "Choose where the ride finishes"
        }
    }

    var systemImage: String {
        switch self {
        case .start:
            return "location.north.fill"
        case .finish:
            return "mappin"
        }
    }
}
