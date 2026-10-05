# Zforge's static 7-Zip

The 26.02 snapshot in `Vendor/7zip` comes from the revision recorded in `Vendor/7zip-provenance.json`. The upstream sources are unpatched. This directory's makefile adapts the official `Format7zF` bundle into a static library, without a console entrypoint or external codecs. It retains multithreading, ARM64 optimization of the LZMA decoder, and codec hardware intrinsics.

The app supports only **arm64** and **macOS 26.0 or later**. The `Build SevenZipCore` phase uses explicit inputs in `inputs.xcfilelist`, keeps the Xcode script sandbox enabled, and stores objects only in DerivedData. The linker uses `-force_load` on the library solely to preserve format/codec registrations. The library is not copied into the bundle.

## Recompile and relink

1. Obtain Zforge's complete corresponding source, including `Vendor/7zip`, this directory, and `Zforge/Native`.
2. Open `Zforge.xcodeproj` with Xcode including the macOS 26 SDK or later.
3. Make the desired change to the engine sources. If you add files, include their objects in the manifest and update `inputs.xcfilelist`.
4. Run `xcodebuild build -project Zforge.xcodeproj -scheme Zforge -configuration Release -destination 'platform=macOS' -derivedDataPath /private/tmp/ZforgeRelink CODE_SIGNING_ALLOWED=NO`. You can also select your own signing identity in Xcode.
5. The new library will be compiled and incorporated into the executable generated in `Build/Products/Release/Zforge.app`. The distributor's signature is not required to recompile; local signing, filesystem access, and execution follow macOS policies.

To compile only the engine: `bash BuildSupport/SevenZip/build.sh /private/tmp/SevenZipCore Release`.

## Licenses

Read `Vendor/7zip/DOC/License.txt`, `copying.txt`, and `unRarLicense.txt` in full. Zforge's Objective-C++ bridge is provided under LGPL-2.1-or-later. Upstream BSD/public-domain notices and the unRAR restriction are preserved in the sources and the complete distributed license; RAR is read-only. Publishing each release's corresponding source and scripts with the distribution materials remains a release requirement.

## Limitations

Failure to decode encrypted headers after a password request can mean an invalid password or corruption of those headers; the domain preserves the current password flow. Item-data errors are not generically converted into invalid-password errors. In-process execution means that fatal native failures can terminate the application.
