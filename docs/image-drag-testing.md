# Image drag-and-drop testing

Image rows and the loaded image in the preview pane export the original image as a PNG.
Existing PNG bytes are preserved; other image formats are normalized at full resolution,
including photo orientation. Text and copied file entries are outside this feature's scope.

The drag payload owns image bytes independently of the UI and history. The native drag
pasteboard supplies PNG data and a file URL for destinations that expect existing files.
Exports use `Image-<SHA256 of original bytes>.png` names, never OCR text. Separate drags
of identical image bytes reuse the same cached PNG without re-encoding or rewriting it.
Different source bytes have separate entries; visually identical images with different
encodings are not deduplicated. Missing exports are recreated on demand. Files live in
the app's temporary `MaccyImageDrags` directory. Each reuse refreshes the expiry time.
Files unused for 24 hours are removed on launch or the next export; they are deliberately not removed when the popup or drag session ends because
the receiving app may still need to read them. Destinations that only open the temporary
file should save their own copy for permanent storage.

## Automated checks

Run the unit suite with Xcode's Maccy scheme, or:

```sh
xcodebuild -scheme Maccy -destination 'platform=macOS' \
  -derivedDataPath /tmp/MaccyDragBuild -only-testing:MaccyTests \
  test CODE_SIGNING_ALLOWED=NO
```

`ImageDragPayloadTests` covers PNG byte preservation, resolution and transparency,
TIFF/JPEG conversion, photo orientation, corrupt input, provider lifetime, image/file/URL
representations, concurrent requests across separate drags, cache reuse without rewriting,
expiry refresh, recreation after deletion, distinct images, and stale export cleanup.

## Live checks

Quit the installed Maccy before running the development build so its shortcut does not
compete with the test app. Launch the development app with `enable-testing` to use an
in-memory history and isolated preferences. Do not replace the installed app.

For both a history row and the loaded image in its preview:

1. Capture a screenshot directly to the clipboard and open the popup.
2. Drag the image to an empty Finder folder. Open the PNG and compare its dimensions
   and contents with the original screenshot.
3. Drag to a browser file-upload area in Chrome and Safari. Confirm it receives one PNG
   with the expected image rather than path text, and that dropping does not submit it
   automatically unless the destination normally behaves that way.
4. Drag into a VS Code editor area to open the image. Test an attachment area separately
   if that is the intended workflow; drop behavior belongs to each destination.
5. Drag into a document in Pages or another native image destination.
6. Start a drag and press Escape; check normal copying/pasting and the clipboard remain
   unchanged. Repeat successful drags and confirm the popup remains usable.
7. Check clicking an image still performs the configured copy/paste action, while dragging
   does not paste or move the popup. Repeat with popup positioning at the menu bar and cursor.
8. Check keyboard selection, image pinning, text rows, and VoiceOver activation still work.
9. Repeat with a large screenshot, a transparent PNG, and a rotated JPEG or HEIC photo.

Provider unit tests alone cannot establish cross-application gesture compatibility.

## Inspecting cache reuse

For the sandboxed development app, use Finder's Go to Folder with:

```text
~/Library/Containers/org.p0deje.Maccy/Data/tmp/MaccyImageDrags
```

To compare the cache before and after dragging the same history image again:

```sh
ls -liT "$HOME/Library/Containers/org.p0deje.Maccy/Data/tmp/MaccyImageDrags"
```

The content-hash filename, inode (first column), and size should remain unchanged.
The modification time is intentionally refreshed for expiry. Finder can create another
destination copy on every drop; those copies are outside Maccy's cache. Temporary files may also be purged by macOS; missing cache entries are recreated on demand.

## Native drag behavior

An AppKit drag source explicitly supplies the floating image and closes the popup after
successful drops. Cancelled/rejected drops keep it open. Normal clicks invoke the existing
copy/paste action; keyboard and VoiceOver activation remain available on the history row.
The floating preview fits within 240 × 160 points without changing the exported resolution.
The native pasteboard representation is covered by programmatic tests. Gesture behavior
and destination compatibility require the live checks above.
