# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.6.2] - 2020-03-12

### Fixed

- Caught request errors when creating deploy on Netlify
- Fix page type option on new command

## [0.6.1] - 2019-11-23

### Removed

- Dependency on dotenv package

### Changed

- Generated dates by `new` command to `YYYY-MM-DD` format.

## [0.6.0] - 2019-07-16

### Added

- Fallback mechanism for loading templates.

## [0.5.0] - 2019-07-12

### Added

- Command to deploy to Netlify.

## [0.4.0] - 2019-06-29

### Added

- Date format to config.
- Site config to template locals.
- Ability to omit template file extension.
- Posts and tags archive page generation.

## [0.3.0] - 2019-06-21

### Added

- Directory for non-page static assets.

### Removed

- Deploy flag `-d` from build command.

## [0.2.0] - 2019-06-21

### Added

- Command to initialize a new project.

### Changed

- Use environment variables (dotenv) for config instead of YAML file.

## [0.1.0] - 2019-06-17

### Added

- Command to create a new page from a title.
- Command to generate pages in a source directory.
