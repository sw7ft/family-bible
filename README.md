# Family Bible

A quiet family Bible for iPhone and iPad. Public-domain English text only. Published by [SW7FT](https://github.com/sw7ft). App Store notes: [docs/APPSTORE.md](docs/APPSTORE.md).

**Read** World English, Basic English, or King James. **Mark a place.** Write **notes, comments, devotions, and prayers** under a family profile. Comments show on the verse with that person’s name. Hold a verse, then tap a word to leave a note on that word. **Maps** are twenty-four plates from George Adam Smith’s 1915 atlas.

Nothing is sent off the phone. No account. No ads. No tracking.

- App Store support: https://sw7ft.github.io/family-bible/
- Privacy: https://sw7ft.github.io/family-bible/privacy.html
- Sources: [LEGAL.md](LEGAL.md)

The product name is **Family Bible**. The iOS bundle id is still `com.sw7ft.quietbible` so existing installs keep their notes. Team `RB6YQW2B5J`.

## Build

Needs Xcode 16+, [XcodeGen](https://github.com/yonaskolb/XcodeGen), and an Apple Development team.

```bash
xcodegen generate
open FamilyBible.xcodeproj
```

To install on a plugged-in iPhone:

```bash
echo YOUR_UDID > .device
bash deploy-device.sh
```

`.device` is local and not committed.

## What is in the app

| | |
|---|---|
| Text | WEBU (default), BBE, KJV — public domain |
| Family | Profiles top-right; each person keeps their own writing |
| Journal | Notes, comments, devotions, prayers, answered prayers |
| Search | Reference or a word; Look farther down keeps going past the first page |
| Maps | Smith 1915 Holy Land plates, public domain |
| Pictures | Camera or library, stored on device only |

## License

Application code is MIT (see `LICENSE`). Bible text and atlas plates are public domain; see `LEGAL.md`.
