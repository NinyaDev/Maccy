# Image drag-and-drop testing

Image rows and the loaded image in the preview pane export the original image as a PNG.
Existing PNG bytes are preserved; other image formats are normalized at full resolution,
including photo orientation. Text and copied file entries are outside this feature's scope.

The provider owns image bytes independently of the UI and history. It supplies PNG data,
a PNG file representation, and a file URL for destinations that expect existing files.
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
