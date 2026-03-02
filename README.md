# UNOLO Task

UIKit + MVVM iOS app that fetches photos from `https://jsonplaceholder.typicode.com/photos`, persists them in Core Data, and supports title edit/delete flows.

## Tech Stack
- Language: Swift 5+
- UI: UIKit (`UITableView`)
- Architecture: MVVM
- Networking: `URLSession`
- Persistence: Core Data
- Image caching: `NSCache` (custom `ImageLoader`)
- Dependency manager: Swift Package Manager
- Minimum iOS: 15.0

## Features Implemented
- Fetch photos from REST API.
- Store photos in Core Data with entity fields:
  - `id` (Int64)
  - `albumId` (Int64)
  - `title` (String)
  - `url` (String)
  - `thumbnailUrl` (String)
- On launch:
  - Load from Core Data first.
  - If Core Data is empty, fetch from API and persist all records.
- Paginated/lazy list rendering:
  - `UITableView` loads records from Core Data in batches of 20.
  - Infinite scroll appends next batch while scrolling.
- Each row shows thumbnail + title.
- Edit title screen:
  - Shows full-size image (`url`) and editable title.
  - Saves updated title to Core Data and reflects in list.
- Delete support:
  - Swipe-to-delete from list with confirmation.
  - Delete button in detail with confirmation.
- Error and empty-state handling:
  - Alert messages for API/Core Data errors.
  - Empty state when no records exist.

## Project Structure
- `UNOLO Task/Models` - API and view data models
- `UNOLO Task/Services` - API, Core Data, image loader/cache
- `UNOLO Task/ViewModels` - business logic for list/detail
- `UNOLO Task/Views` - view controllers and table view cell
- `UNOLO Task/CoreData` - Core Data model
- `UNOLO Task/App` - app lifecycle and configuration

## Setup & Run
1. Open `UNOLO Task.xcodeproj` in Xcode.
2. Select `UNOLO Task` scheme.
3. Run on an iOS Simulator (iOS 15.0+).

## Assumptions / Notes
- API may return unreachable placeholder image URLs in some environments. A deterministic fallback is used so thumbnail/full-image remain visually consistent.
- Upsert-by-id is used to avoid duplicate Core Data records.

