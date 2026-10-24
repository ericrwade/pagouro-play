# Jigsaw by Pagouro on the App Store

Filled 2026-10-24 through the App Store Connect API (`tools_src/asc_listing.py`, run by
`.github/workflows/appstore-listing.yml` with the repo's ASC secrets; `inspect` reads, `apply` writes, neither submits).
The text lives in `store/app_store.json`; edit it there and run `apply` again.

## Done by the API (verified in the run log, run 40111271734)

- Version **0.3.3** (the empty "1.0" draft renamed), release **manually** (Apple's Managed publishing), build **24** attached.
- Name, subtitle "Relaxing jigsaws, no ads", description, keywords, promotional text, support and marketing URL
  (pagouro.com/jigsaw/), privacy policy URL, copyright "2026 Pagouro".
- Category Games › Puzzle.
- Age rating questionnaire: every category None / No.
- Review notes (no sign-in needed).
- Screenshots: 5 iPhone 6.9" (1320×2868) and 5 iPad 13" (2064×2752), all processed COMPLETE. Made by
  `main.gd -- --shots --shot-size=WxH --sim-safe=T,B` (borderless window, so not clamped to the desk's screen) and
  captioned by `tools_src/make_appstore_shots.py`. Raw renders in `store/screenshots/raw_iphone|raw_ipad`.
- Privacy policy page now names iPhone and iPad and has an App Store section (pagouro-site commit c287003).

## Left for Eric in App Store Connect (the API can't do these, or they're his to say)

1. **App Privacy** (sidebar): Get Started → "No, we do not collect data from this app" → Publish.
2. **Pricing and Availability:** Price **Free** (USD 0.00); availability: all countries.
3. **App Review Information** (on the 0.3.3 page): contact first and last name, phone, email. Notes are already in.
4. **Content rights** (App Information): "No, it does not contain, show, or access third-party content."
5. Open the age rating once to confirm it shows **4+**.
6. **Add for Review**, then **Submit to App Review**. With manual release, approval waits for your Release button.
