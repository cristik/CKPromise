## 1.4.6
- Added CHANGELOG

## 1.4.5
- Renamed readme.md to README.md, no library changes

## 1.4.4
- Improved README
- Updated the .travis.yml file to use the latest Xcode (7.1)

## 1.4.3
- Fixed podspec by linking with libc++

## 1.4.2
- Fixed .mm files not being included in podspec

## 1.4.1
- C++-ified the callback array, for better performance

## 1.4.0
- Simplified the promise - got rid of unnecessary and performance-prone stuff
- Bakcwards incompatible with the previous versions

## 1.3.2
- Also handling BOOL and Class as first callback parameters
- Simplified the `then` methods

## 1.3.1
- Performance improvements

## 1.3.0
- Removed queuedPromise, fixed some deadlocks

## 1.2.0
- Addressed the thread safety issue, added queued `then`

## 1.1.0
- Creating promises with dispatchers

## 1.0.3
- Added support for integration with Travis CI

## 1.0.2
- Added `queuedThen` property
- Some unit testing refactoring

## 1.0.1
- Added support for specifying the callback queue

## 1.0.0
- First public version with support for cocoapods