# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-01-09

### Added
- Initial release
- Import hints feature
  - Shows which symbols are used from each import
  - Virtual text annotations via extmarks
  - Toggle and refresh commands
- Receiver highlight feature
  - Highlights method receiver variable in unique color
  - Configurable highlight color
- Error dim feature (experimental)
  - Dims repetitive `if err != nil { return err }` blocks
  - Configurable for simple vs wrapped returns
- User commands: `:GoImportHints`, `:GoImportHintsToggle`, `:GoErrorDimToggle`, `:GoErrorDimStatus`
- Comprehensive test suite (39 tests)
