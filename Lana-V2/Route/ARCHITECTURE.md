# Route Architecture

The Route module uses feature-based MVVM. A feature owns its UI, observable
state, and feature-specific services. Types shared by more than one feature
live under `Shared`.

## Dependency Direction

```text
Views -> ViewModels -> service protocols -> service implementations
                    -> shared domain models
```

- Views render state and forward user actions.
- ViewModels own presentation state and coordinate asynchronous work.
- Protocols describe dependencies without exposing Apple framework objects.
- Framework implementations translate MapKit, Core Location, and AVFoundation
  values into domain models.
- Feature folders may depend on `Shared`; `Shared` does not depend on features.

## Features

### CreateRoute

- `CreateRouteViewModel` owns route type, distance, selected waypoints,
  validation, generation state, and navigation to route options.
- `RoutePointPickerViewModel` owns place suggestions, pin selection, current
  location, and resolving a coordinate into a user-facing place name.
- `RouteCandidatePlanner` creates progressive loop and A-to-B search stages.
- `RouteGenerationPolicy` defines acceptable distance tolerances.
- `RouteRankingService` deduplicates and scores route candidates.
- `RouteGenerationService` orchestrates cycling-first generation and road
  fallback without importing MapKit.
- `MapKitPlaceSearchService` owns autocomplete, suggestion resolution, and
  nearby point-of-interest lookup.
- `MapKitLocationNamingService` owns iOS 26 reverse geocoding.
- `LocationService` owns only Core Location authorization and one-shot GPS.

Location picker data flow:

```text
Typed query + visible map region
  -> RoutePointPickerViewModel
  -> PlaceSearching
  -> MapKitPlaceSearchService / MKLocalSearchCompleter
  -> [PlaceSearchSuggestion]
  -> resolve selected suggestion
  -> RouteLocation
  -> CreateRouteViewModel

GPS / map tap / dragged pin
  -> RouteCoordinate
  -> nearby POI lookup + reverse geocoding
  -> RouteLocation
  -> CreateRouteViewModel
```

Create route data flow:

```text
User input
  -> CreateRouteViewModel
  -> RouteGenerationRequest
  -> RouteGenerationService
  -> RouteCandidatePlanner
  -> DirectionsProviding
  -> MapKitDirectionsService
  -> RouteLeg
  -> Route ranking/policy
  -> [Route]
  -> RouteOptionsViewModel
  -> RouteDetailViewModel
```

### RouteDetail

`RouteDetailViewModel` owns the selected `Route`, detail-sheet state, weather,
route naming, favorite intent, and the handoff into live navigation. Weather
is loaded through `RouteWeatherProviding`; the WeatherKit adapter is isolated
under `Services/WeatherKit`. Saving and favorites use `RouteSaving`.

Route detail data flow:

```text
Selected Route
  -> RouteDetailViewModel
  -> RouteDetailsSheet + map
  -> RouteWeatherProviding -> WeatherKit -> RouteWeatherDisplay
  -> RouteSaving -> SavedRoutesViewModel -> RoutePersisting
  -> Start Ride -> LiveNavigationView
```

### SavedRoutes

`SavedRoutesViewModel` owns persisted routes, filtering, favorites, selection,
and storage errors. `UserDefaultsRouteStore` is the persistence adapter.

### LiveNavigation

- `CoreLocationLiveTrackingService` publishes domain location events.
- `MapKitRouteProgressService` projects a location onto the route polyline.
- `NavigationReroutingService` requests replacement directions.
- `AVSpeechNavigationService` owns voice output.
- `LiveNavigationViewModel` owns the ride lifecycle and navigation state.

Live navigation data flow:

```text
Core Location
  -> NavigationLocationSample
  -> LiveNavigationViewModel
  -> MapKit route projection
  -> progress / instruction / off-route decision
  -> LiveNavigationView
```

The ViewModel requests rerouting after three consecutive samples more than
100 meters from the route and applies a 20-second cooldown. Cycling directions
are tried first; road geometry is only a fallback.

## Shared

- `Models` contains framework-independent route entities.
- `Infrastructure/Contracts` contains cross-feature service contracts.
- `Infrastructure/MapKit` is the shared MapKit adapter layer.
- `Theme` contains the Route visual tokens used by every feature.
