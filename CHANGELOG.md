# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Fixed
- Increased the upload limit for media files so larger MP4/WEBM maps no longer fail with file-size errors.
- Made the Pi restart helper use non-interactive npm commands so the update path completes reliably on the remote host.
- Updated the map library layout to stack cards top-to-bottom with consistent sizing and fixed the video-control polling path used by Play/Pause actions.
- Prevented Git refreshes from overwriting uploaded map data by excluding runtime data files from version control.
- Restored the Pi runtime startup path by fixing the display launcher and documenting the dependency/build requirement for `npm run build`.

## [1.0.2] - 2026-06-08

### Fixed
- Protected uploaded map data and media files from being wiped by pull/update operations.

## [1.0.1] - 2026-06-08

### Fixed
- Replaced the browser prompt-based map edit flow with an in-page edit dialog so the Edit button works in the admin interface.

### Changed
- Added server-backed display control syncing to support the Pi display path more reliably.

## [1.0.0] - 2026-06-07

### Added
- Initial release of the KnoxRPG Digital Terrain application.
- Project documentation and setup guidance.
