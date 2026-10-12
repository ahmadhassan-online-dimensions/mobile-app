---
name: design
description: Design rules and the VUE & OR brand source for this Flutter app. Use for any request that changes how the app looks or adds/restyles screens - theming, layout, splash, icons, new pages, "make it look like the design", applying the VUE & OR wireframes.
---

# Design (Flutter, VUE & OR)

Adapted for this Flutter project from the "Design (canvas)" skill shared by the
user. The canvas-publishing mechanics (`.dc.html` artboards, `canvas.json`,
uploads) were dropped; the design-quality rules and the brand source were kept.

## 1. Start from the source, not from scratch

- Brand and screens: read `reference/vue-and-or-brand.md` first. The original
  web wireframes are in `reference/vue-and-or-wireframes/*.dc.html` (HTML with
  inline CSS): open the one matching the screen you're building and copy its
  structure, copy text and values. They are web layouts at 1440px; adapt to a
  ~390dp phone (stack columns, keep order and content).
- Existing app: follow what `lib/theme.dart` (AppColors, buildTheme) and the
  screens in `lib/screens/` already do. Put new colours/text styles in
  `lib/theme.dart` as tokens, never as one-off hex values in widgets.
- Logo: `assets/images/logo.png` (generated from Garamond). Icon/splash colours
  are in `android/app/src/main/res/values/colors.xml`.
- Missing facts (prices, names, policies) stay visible placeholders such as
  `AED [PRICE]` or `[Model 01 name]`. Never invent prices, stats or reviews.
- Missing image/asset: draw a clean placeholder (tinted box + label/icon)
  rather than a bad imitation.

## 2. Settle open decisions before building

Full rules: `reference/questions.md`. In short: if the request leaves two or
more result-changing design decisions open and the user is present, ask ONE
`AskUserQuestion` (max 4 questions, concrete options from their material,
recommended first). One small default you can pick: decide and state it.
Small, targeted requests: no questions.

## 3. Craft rules (long form: `reference/craft.md`)

- Commit to a small system: 1–3 typefaces, one ground, 0–2 accents. For
  VUE & OR: serif display (Cormorant Garamond look) over a clean sans body,
  ink `#1F1D1A` on `#F7F5F1`, gold `#C9A45C` as the only accent.
- No filler: no lorem ipsum, dummy sections or decorative stats. Every element
  earns its place; ask before adding new sections or copy.
- Targeted changes stay targeted: change only what was asked; suggest the rest.
- Avoid AI-slop tropes: gradient washes, emoji as UI, left-border accent cards,
  default-looking Roboto/Inter-only screens.
- Motion: one well-orchestrated moment (e.g. splash fade) beats many small ones.
- Don't recreate another company's proprietary design.

## 4. Flutter specifics

- Touch targets ≥ 48dp (IconButton default is fine; custom taps need padding).
- Accessibility: real buttons (`ElevatedButton`, `IconButton`, `InkWell` with
  semantics), `tooltip`/`semanticLabel` on icon-only controls and images.
  Text contrast ≥ 4.5:1 (3:1 at 24sp+); grey captions and text on gold fail
  most often — darken them. Colours that must be told apart also differ in
  lightness.
- Phone first: test at 360dp wide, long text, and large font scale; no
  overflow stripes; wrap chips; scroll long content; respect `SafeArea`.
- Never draw a fake status bar or keyboard.
- Fonts: Android's built-in `serif` is the no-download fallback. Bundling
  Cormorant Garamond / Instrument Sans (both open-licence Google Fonts) needs a
  font download — ask the user before downloading.

## 5. Verify like the rest of this project

After a design change: `flutter analyze`, `flutter test` (update widget tests
that look for changed text), then build and check on the emulator with
screenshots (`adb exec-out screencap -p` via Bash; PowerShell `>` corrupts
binary). Report what you saw.
