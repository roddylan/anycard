# Handoff: Barcode → Wallet Cards (mobile app)

## Overview
A mobile app (iOS-first, shown in an iPhone frame) that lets a user turn any
barcode/QR code into a saved "pass" in a personal wallet, similar in spirit to
Apple Wallet. The user scans (or manually enters) a code, customizes a pass
design (template, colors, icon, member details), confirms, and the pass lands in
a scrollable list of cards. Tapping a card opens a full-screen "Scan pass" view
optimized for showing the code to a reader.

The flow: **Home (wallet list) → Add (scanner) → Customize → Add-to-Wallet
confirm → back to Home**, plus **Home → Pass detail/scan → Home**.

## About the Design Files
The files in this bundle are **design references created in HTML** — an
interactive prototype showing intended look and behavior. They are **not
production code to lift directly**. They run on a small in-house HTML component
runtime ("Design Components": `.dc.html` files + `support.js`), which will not
exist in your codebase.

Your task is to **recreate these designs in the target app's existing
environment** (React Native, SwiftUI, Flutter, a React web app, etc.) using its
established components, navigation, and styling patterns. If no app environment
exists yet, choose the most appropriate framework for a mobile app and implement
there. Treat the HTML/JS as the source of truth for *layout, spacing, color,
typography, copy, and interaction* — not as an architecture to mimic.

### How to read the source
- `Wallet Cards.dc.html` — the whole app: all five screens, navigation state,
  and the barcode-glyph generators. The markup between `<x-dc>...</x-dc>` is the
  template (inline styles = the exact visual spec). The `<script ...>class
  Component extends DCLogic` block is the logic (state + handlers + `renderVals`
  which computes per-render values). Ignore the `{{ ... }}` template holes,
  `sc-if`/`sc-for`, and `dc-import` tags — those are runtime constructs; read the
  inline styles and the JS.
- `Pass.dc.html` — the pass "card" component, rendered inside Customize, Confirm,
  and Detail. It has **five templates** (minimal, membership, feature, poster,
  photo). Same structure: template + logic.
- `ios-frame.jsx`, `image-slot.js`, `support.js` — runtime/scaffolding only
  (device bezel, drag-drop image placeholder, component runtime). Do **not** port
  these; use your platform's real device chrome and image pickers.

## Fidelity
**High-fidelity.** Colors, typography, spacing, radii, shadows, and copy are all
final. Recreate the UI pixel-accurately with your codebase's libraries. The one
thing that is intentionally *fake* is the barcode rendering — see "Barcodes".

## Design Tokens

### Colors
- App background (behind frame): `#E9E5DC`
- Screen background (light): `#F4F1EA`
- Add / scanner background (dark): `#12110E`
- Wallet-confirm scrim: `rgba(12,11,9,0.94)`
- Primary text: `#221E17`
- Muted text: `#8A8478`; fainter label text: `#A39B8B`
- Primary accent (buttons, active ring): `#C6512F`; hover `#a8492f`
- Accent (links/secondary on dark): `#E7724E`
- Card/input surface: `#FFFFFF`; input border `#E4DFD3`
- Segmented-control track: `#EBE6DA`
- Info/hint panel: bg `#F0E9DA`, dashed border `#D8CDB4`, icon `#B8703E`, text `#6E675A`
- Toast: bg `#221E17`, text `#F4F1EA`, check icon `#8FC79E`
- Barcode ink (on white code box): `#141410`

### Pass themes (each: gradient bg / solid dot / foreground text)
- forest — gradient `linear-gradient(155deg,#455A4D,#33463C)`, solid `#3E5145`, fg `#ECE6D5`
- coral — gradient `linear-gradient(155deg,#CB6142,#B14A30)`, solid `#C05939`, fg `#FBEEE6`
- midnight — gradient `linear-gradient(155deg,#2C2C33,#1E1E23)`, solid `#26262B`, fg `#F3F1EC`
- sand — gradient `linear-gradient(155deg,#E7DBC0,#DACBA6)`, solid `#DDCEAB`, fg `#3B352A`
- plum — gradient `linear-gradient(155deg,#7E5CA8,#5F3F86)`, solid `#6E4E96`, fg `#F0E7F7`
- slate — gradient `linear-gradient(155deg,#42506A,#333F54)`, solid `#3B4860`, fg `#E8EEF5`

Photo templates (feature/photo) use a dark canvas `#141210` behind the image and
white text with gradient scrims top/bottom.

### Typography
- **Newsreader** (serif) — display/headings: screen titles, org name, member name.
  Weight 500 for titles.
- **Hanken Grotesk** (sans) — UI text, labels, buttons. Weights 400/500/600/700.
- **JetBrains Mono** (mono) — code values, member IDs, dates. Weights 500/600.
- Section/eyebrow labels: 11–12px, uppercase, letter-spacing ~0.09em, weight 600, muted.
- Screen title: Newsreader 42px (Home "Cards"), 26px (Add/Customize), 28px (Confirm).

### Spacing / radius / shadow
- Screen horizontal padding: 18–24px. Top padding accounts for status bar (~60–66px).
- Card radius: 24px (wallet rows), pass card 24px, inputs 12–14px, pills/FAB 999px.
- Icon tiles: 44–46px, radius 13–14px.
- Card shadow: `0 8px 22px rgba(30,26,18,0.13)`.
- Primary button shadow: `0 10px 26px rgba(198,81,47,0.42)`.
- Pass shadow: `0 18px 44px rgba(20,18,12,0.28)`.

### Icons
Phosphor Icons (`@phosphor-icons/web` v2.1.1), bold + fill weights. Icon set used
for passes: `barbell, train-simple, coffee, storefront, ticket, book-open,
butterfly, key, heart, mountains`. UI: `plus, caret-left, caret-right, wallet,
lock-simple, sun, image, image-square, scan, dots-three, check, check-circle,
square-half, identification-card, frame-corners`. Map these to your icon library.

## Screens / Views

### 1. Home — Wallet list
- **Purpose**: See all saved passes; open one; add a new one.
- **Layout**: Vertical flex. Header ("Cards" + "N passes in your wallet"), then a
  scrollable column of card rows (gap 14px, bottom padding 132px to clear the FAB),
  then a centered pill FAB pinned 30px from bottom.
- **Card row**: rounded 24px, padded 18px, background = theme (gradient or solid
  per pass), foreground = theme fg. Contains: a faint oversized `fill` icon
  bleeding off the top-right corner (opacity 0.08); a header row with a 44px icon
  tile, name (Newsreader 22px) + code-type label (11px uppercase), and a
  caret-right; and a white code strip (radius 15px) holding the code glyph + the
  code value in mono. Press state: `scale(0.972)` + reduced shadow.
- **FAB**: "Add a card" pill, `#C6512F`, white, height 56px, plus icon.
- **Interaction**: tap a row → Pass detail; tap FAB → Add.

### 2. Add — Scanner
- **Purpose**: Capture a code via camera (simulated), manual entry, or image.
- **Layout**: dark screen. Back button + "Add a card" title. A square camera
  viewport (radius 28px, radial dark gradient, four L-shaped corner brackets in
  `#F4F1EA`, hint text "Point at any barcode or QR code"). Below: 4 format pills
  (QR / Barcode / PDF417 / Aztec). Then a spacer, then the capture cluster: a 74px
  round shutter button, "Tap to simulate a scan", an "Enter code manually" toggle
  link (`#E7724E`), and a "Code won't scan? Capture it as an image" link.
- **Manual entry** (toggles open): a panel with a mono text input for the code
  value and a row of code-type chips (active chip = `#E7724E` on `#12110E`), plus a
  "Continue" button.
- **Interaction**: shutter → randomly picks a code type + generated value → Customize.
  Manual "Continue" → Customize with entered/typed values. Image link → Customize
  with codeType `image`.

### 3. Customize
- **Purpose**: Design the pass and fill member details before saving.
- **Layout**: light screen, scrollable, with a sticky bottom "Add to Wallet"
  button over a gradient fade. Sections top→bottom:
  1. **Template** — 2-col grid of 5 option tiles (icon + label + hint). Active tile
     inverts to `#221E17`/`#F4F1EA`.
  2. **Live preview** — the `Pass` component rendered with the current draft.
  3. **Member name** — text input.
  4. **Background** (only for non-photo templates) — a Solid/Gradient segmented
     control, a row of 6 color swatches (44px circles; active has a 3px `#C6512F`
     ring + white check), and a "Show icon in background" toggle switch.
  5. **Feature/photo hint** (only for photo templates) — dashed info panel telling
     the user to drop a photo on the preview.
  6. **Icon** — wrap row of 10 icon tiles (active inverts).
  7. **Details** — 2-col grid of inputs that **changes per template** (see
     "Adaptive detail fields").
  8. **Code type** — read-only row with a lock icon showing the detected type.
  9. **Image-code hint** (only when codeType = image).
- **Interaction**: every control live-updates the preview. Back → Add. "Add to
  Wallet" → Confirm.

### 4. Add-to-Wallet — Confirm
- **Purpose**: Final confirmation.
- **Layout**: near-opaque dark scrim over the app. Title "Add to Wallet" +
  subtitle. Centered pass preview (max-width 320px) that pops in
  (`scale(0.92)→1`, opacity 0→1, 0.5s). Bottom row: "Cancel" (secondary) + "Add"
  (primary, flex 2).
- **Interaction**: Cancel → Customize. Add → prepend new card to the list, return
  Home, show toast "Added to your wallet" (auto-dismiss ~2.4s).

### 5. Pass detail / Scan
- **Purpose**: Present the pass full-screen for scanning.
- **Layout**: full-screen, background = the pass's solid theme color (or `#141210`
  for photo templates), foreground = theme fg. Top bar: back button, "Scan pass"
  title (Newsreader 20px), overflow (dots-three) button. Centered pass (max-width
  342px). Below it: "Brightness increased for scanning" with a sun icon.
- **Interaction**: back → Home.

## The Pass component (5 templates)
Rendered from a data object: `{ template, name, org, tier, memberId, since,
expires, guestPass, guestNo, passType, bg, fg, icon, showIcon, codeType,
codeValue, imgId }`. Card aspect ratio **320:442**, radius 24px.

- **minimal** — org + tier header, big centered member name, white code box at
  bottom. Optional faint watermark icon.
- **membership** — org + "Membership"/tier header, a rotated large `fill` icon
  accent, member name, member ID, a row of Since/Expires/Guest-pass, and a white
  code box footer.
- **feature** — full-bleed **photo background** with top+bottom dark scrims, org +
  guest-no header, a centered white code box, and name/passType/expires footer.
  White text throughout.
- **poster** — **photo on top** (with org + icon overlay), then a solid panel below
  with member/passType/expires and a white code box.
- **photo** — full-bleed photo like feature, but code box sits higher and the layout
  is a poster/full-bleed variant.

### Adaptive detail fields (Customize → Details section)
- minimal: Organization, Subtitle (each full-width)
- membership: Organization, Tier, Member ID (full), Member since, Expires, Guest pass (full)
- feature: Organization, Guest no., Pass type, Expires
- poster: Organization, Pass type, Expires (full)
- photo: Organization, Guest no., Pass type, Expires

Empty fields fall back to placeholder defaults in the rendered pass (e.g. name →
"Your name", expires → "01/2027").

## Barcodes (IMPORTANT)
The prototype **fakes** all codes with deterministic pseudo-random pixel/bar
patterns (seeded by a hash of the value) purely for looks — they are NOT scannable
and encode nothing. In production, **use a real barcode/QR library** for your
platform (e.g. a QR encoder + a Code128/PDF417/Aztec generator) and render the
actual value. Supported types in the UI: `qr`, `code128` (Barcode), `pdf417`,
`aztec`, plus `image` (user supplies a photo of the code). Render on a white
rounded box sized to hug the code (square for QR/Aztec, wide for Code128/PDF417).

## Interactions & Behavior
- **Navigation** between the four stacked screens (home/add/customize/wallet) slides
  horizontally: forward screen enters from the right (`translateX(100%)→0`),
  previous eases left (`→ -24%`), 0.44s `cubic-bezier(.22,1,.36,1)`, opacity
  cross-fade 0.38s. Implement with your platform's native stack navigation.
- **Pass detail** currently opens as a simple opacity cross-fade (0.18s). NOTE: an
  animated "splash"/shared-element expand (card grows to fill the screen) was
  prototyped and then removed at the client's request — it's intentionally not in
  this version. If asked for it later, it was a `clip-path` inset growing from the
  tapped card's rect + a FLIP transform on the pass.
- **Confirm** pass pops in (scale + fade, 0.5s).
- **Toast** slides down + fades in (0.3s), auto-dismisses ~2.4s.
- **Press feedback** on cards/swatches/icons: subtle `scale` down.
- Scanner shutter picks a random code type; manual entry respects typed values.

## State Management
Single screen state machine plus a working "draft" pass:
- `screen`: `home | add | customize | wallet | detail`
- `cards[]`: saved passes (see data shape above). Seeded with 4 samples.
- `draft`: the in-progress pass being added (null when not adding).
- `detailId`: which saved card the detail view shows.
- `manual`, `toast`: UI flags.
Handlers: `openAdd, simulateScan, manualContinue, captureImageCode, pickTemplate,
pickTheme, pickIcon, setFill, toggleBgIcon, pick<Field>, toWallet, confirmAdd,
openDetail, goHome, back*`. Adding a card prepends it to `cards`. No persistence /
no network in the prototype — wire to your real store + a real code scanner.

## Assets
- No bundled raster assets. Icons come from Phosphor Icons (see Icons). Photo
  templates use user-supplied images (drag-drop `image-slot` placeholder in the
  prototype → replace with a real image picker/camera).
- Fonts: Newsreader, Hanken Grotesk, JetBrains Mono (Google Fonts).

## Files
- `Wallet Cards.dc.html` — full app (all screens, state, navigation, fake barcodes).
- `Pass.dc.html` — the pass card component (5 templates).
- `ios-frame.jsx`, `image-slot.js`, `support.js` — prototype runtime/scaffolding only; do not port.

To preview the prototype as-authored, open `Wallet Cards.dc.html` in a browser
(all files must sit in the same folder).
