# VUE & OR — brand and product summary

Distilled from the "VUE & OR — Website Wireframes" canvas (files in
`vue-and-or-wireframes/`). Those are WEB wireframes (1440px pages, greyscale
placeholders); translate them to the phone app, don't copy desktop layouts.

## What the brand sells

- 18k gold necklaces with reading glasses hidden inside the pendant
  ("Jewelry, with another point of view." / "From necklace to vision.").
- Two models: **Model 01 · Wearable reader** (unfolds into glasses you wear) and
  **Model 02 · Handheld reader** (unfolds into a lens you hold). Real names are
  still `[Model 01 name]` / `[Model 02 name]` placeholders.
- Two finishes: **Solid 18k gold** and **Gold plated**.
- Lenses: ready readers **+1.00 to +3.00** in 0.25 steps, **My prescription**
  (upload), or **Not sure yet** (they confirm later; good for gifts).
- Extras: engraving, gift box + handwritten card, hidden prices for gifts,
  private viewing (home / office / studio), WhatsApp support.
- Market: UAE. Prices in **AED**, incl. 5% VAT. Unknown facts stay as
  bracketed placeholders like `AED [PRICE]`, `[14]-day returns`; never invent them.

## Screens in the wireframes

| Wireframe | Purpose | Key content |
|---|---|---|
| Main (Home) | Discovery story | hero → everyday problem → the reveal (3 steps) → two models → craftsmanship → lenses → story → reviews → press → gifting → shop → FAQ → private viewing CTA |
| Shop | Browse & compare | filters: All, Wearable, Handheld, Solid 18k gold, Gold plated, Gift-ready; 4 variant cards; comparison table |
| LensGuide | Find your strength | 1. age chips (40–44 → +1.00, 45–49 → +1.50, 50–54 → +2.00, 55–59 → +2.25, 60+ → +2.50); 2. reading test (tap smallest readable line, +3.00…+1.00); 3. suggested strength + "Shop with +X" |
| Product | Configure & buy | finish, lens type, strength, engraving, gift options; how it opens; details; reviews; cross-sell the other model |
| Cart ("Your bag") | Review | line item with finish/lenses/chain/engraving/gift; summary (engraving, gift box, UAE delivery complimentary); promo; Checkout securely |
| Checkout | Pay | express checkout; 1. Contact 2. Delivery 3. Payment; gift-recipient toggle |
| Confirmation | Thank you | order number; 4-step timeline (confirmed → lenses fitted → quality check → delivered); "Not sure yet" note |
| About / Help | Story, viewing form, stockists / FAQ, policies, contact | |

## Visual language (from the wireframes' CSS)

| Token | Value | Use |
|---|---|---|
| Ground | `#F7F5F1` | screen background |
| Ink | `#1F1D1A` | text, primary buttons (filled black, light text) |
| Body text | `#45413C` | paragraphs |
| Muted | `#5E5A55` | eyebrows / captions |
| Card | `#FFFFFF` with `#D8D3CB` 1px border | cards, panels |
| Soft panel | `#EFECE7` | info callouts |
| Input border | `#BDB7AE` | fields, unselected chips |
| Placeholder | `#E4E0DA` fill, `#CFC9C1` border | image placeholders |
| Logo gold | `#C9A45C` | the "&" in the logo; use sparingly as the single accent |
| Logo cream | `#EFE8DE` | splash / icon ground |

- Type: **Cormorant Garamond** 500 for display headings, **Instrument Sans**
  400–600 for UI/body, **JetBrains Mono** 12px uppercase +0.08em tracking for
  eyebrows ("01 — The reveal"). The app's logo asset is Garamond-drawn.
- Shape: square corners (no radius), 1px hairline borders, no shadows.
- Buttons ≥48px tall: primary = filled ink; secondary = 1px ink outline.
- Chips: 44–48px, outlined; selected = filled ink with light text.
- Generous whitespace; dashed `#C9C4BC` dividers between big sections.
