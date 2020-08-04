fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew install fastlane`

# Available Actions
## Mac
### mac bump
```
fastlane mac bump
```
Bump version and build number and set/update changelog
### mac release
```
fastlane mac release
```
Tag, build App Store version and deliver, build developer id version and push to GitHub release
### mac release_app_store
```
fastlane mac release_app_store
```
Build to App Store and send to App Store
### mac release_developer_id
```
fastlane mac release_developer_id
```
Build for developer id and notarize
### mac clean
```
fastlane mac clean
```
Remove the build directory
### mac meta
```
fastlane mac meta
```
Meta

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
