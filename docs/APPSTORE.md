# Family Bible — App Store Connect

Use this when creating the listing. Support and privacy URLs must stay live.

| | |
|---|---|
| Name | Family Bible |
| Subtitle | A quiet Bible for the family |
| Bundle | `com.sw7ft.quietbible` |
| SKU | `family-bible` |
| Version | 1.0 |
| Category | Reference (primary). Books optional secondary. |
| Age | 4+ |
| Price | Free |
| Devices | iPhone (portrait) and iPad (portrait + landscape) |
| Encryption | Exempt — `ITSAppUsesNonExemptEncryption` is `NO` |
| Privacy nutrition | No data collected |
| Support | https://sw7ft.github.io/family-bible/ |
| Privacy | https://sw7ft.github.io/family-bible/privacy.html |
| Copyright | 2026 SW7FT |

## Description

Family Bible is a simple reader for a family to keep together.

Read the World English Bible, Bible in Basic English, or the King James Version. Mark a place. Write notes, comments, devotions, and prayers under a person’s name. Comments appear on the verse. Hold a verse, then tap a word to leave a note on that word. Maps are from George Adam Smith’s 1915 atlas.

The words are public domain. Your writing and pictures stay on the phone. No account. No ads. No tracking.

## Keywords (100 characters)

bible,kjv,king james,scripture,devotion,prayer,family,kjv bible,holy bible

## Review notes

No login. Hold a verse for one second, then tap Note or Comment. After the verse is selected, tap a word to attach the note to that word. Profiles are top-right. On iPad the sections are in a sidebar; Command-← / Command-→ turns the chapter. Settings has Export / Import for the family’s writing (local file only), Write a review, and an optional tip jar (consumable IAP). Tips unlock nothing. Product IDs: `com.sw7ft.quietbible.tip.small` ($0.99 Thank you), `.tip.medium` ($2.99 A coffee), `.tip.large` ($4.99 A meal). Texts are public-domain WEBU, BBE, and KJV. Maps are public-domain 1915 plates. Writing stays on the device. No PayPal or web donate button in the app.

## Screenshots

Need at least one 6.9-inch iPhone portrait shot (1320×2868, 1290×2796, or 1260×2736). iPhone 16 Pro Max is 6.9-inch.

Because the app runs on iPad, also need one 13-inch iPad shot (2048×2732 or 2064×2752 portrait). Suggested: reader with the sidebar, plus a landscape 13-inch if you want.

Do not include alpha. Suggested iPhone set: reader (John 1), a verse with a family comment, Journal, Books / maps, Settings → This Bible.

## Rejection watch

Do these before the first submit. The binary itself is a complete reader; most rejects will be listing or IAP, not missing Bible features.

| Risk | Why they bounce it | What to do |
|---|---|---|
| Dead tip buttons (2.1) | Reviewer taps Thank you and the product is not in App Store Connect | Create the three consumable IAPs, attach them to 1.0, complete Paid Apps Agreement + banking + tax. Release hides the buttons until Apple returns the products. |
| Placeholder copy (2.1) | “Coming soon”, empty screens, broken links | Do not say coming soon. Support and privacy URLs must stay live. |
| Missing screenshots (2.3) | iPhone 6.9-inch and iPad 13-inch are required for this binary | Capture from a Release-style build. Show the real reader, not Debug tip errors. |
| Privacy mismatch (5.1.1) | Nutrition label says you collect data, or policy is missing | Leave “no data collected.” Policy is on the support site and mentions camera, export, and Apple tips. |
| Wrong name (2.3.8) | Listing says Quiet Bible, or screenshots do not match | App Store name is Family Bible. Bundle id stays `com.sw7ft.quietbible`. |
| Web donate (3.1.1) | PayPal / Stripe / donate on a page the app opens | Keep the website as support + review. Tips only through IAP. |
| Called a donation (3.2.2) | “Donate” when you are not a registered nonprofit | Keep the word tip. |
| Debug archive (2.1) | Uploading the `deploy-device.sh` Debug build | Archive Release from Xcode → Any iOS Device. |
| Age / UGC | Treating private notes as public user-generated content | Notes stay on the phone. Age 4+. No login. |
| Copyright (5.2.1) | Shipping NIV/ESV or claiming rights you do not have | WEBU, BBE, KJV (PD in the US), Smith 1915 maps only. |

Support page: https://sw7ft.github.io/family-bible/ — live. Privacy: https://sw7ft.github.io/family-bible/privacy.html — live. A public contact email on that page is safer than GitHub-only.

## Archive

In Xcode: Any iOS Device (arm64) → Product → Archive → Distribute App → App Store Connect. Use the paid team RB6YQW2B5J. Do not upload a Debug build from `deploy-device.sh`.
