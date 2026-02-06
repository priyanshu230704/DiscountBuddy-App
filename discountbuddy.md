📘 DiscountBuddy UI/UX Redesign Specification

(Design-Only Refactor · No API / Flow Changes)

1️⃣ Objective

Redesign the DiscountBuddy mobile application UI/UX to establish a distinct, premium, and modern brand identity, while strictly preserving:

Existing user flows

Existing API contracts

Existing navigation logic

Existing page-level data bindings

⚠️ This is a DESIGN-ONLY change.
No backend, API, routing, or business logic modifications are allowed.

2️⃣ Non-Negotiable Constraints (Read Carefully)
❌ NOT Allowed

No API response changes

No request parameter changes

No new endpoints

No deletion or reordering of screens

No navigation flow changes

No logic refactors hidden as “UI changes”

✅ Allowed

Visual redesign

Layout restructuring within the same screen

Component replacement (buttons, cards, headers)

Theme, typography, spacing, elevation, animation

Dark mode enablement

Reusable UI component creation

If a change risks breaking API bindings → do not do it.

3️⃣ Design Direction
Brand Positioning

DiscountBuddy = Smart Savings Platform

Not coupon-spam.
Not loud discounts.
Not NeoTaste.

Design should communicate:

“I’m saving money intelligently and confidently.”

4️⃣ Color System (Tokenized)
🎨 Core Palette
Role	Color	Token
Primary	Electric Indigo	#4F46E5
Secondary	Soft Violet	#8B5CF6
Success / Savings	Mint Green	#22C55E
Warning	Amber	#F59E0B
Error	Red	#EF4444
Neutral Palette
Usage	Light	Dark
App Background	#F9FAFB	#020617
Surface	#FFFFFF	rgba(2,6,23,0.7)
Text Primary	#0F172A	#E5E7EB
Text Secondary	#475569	#94A3B8
Divider	#E5E7EB	#1E293B

⚠️ No direct hex usage in widgets.
All colors must be consumed via theme tokens.

5️⃣ Typography System
Font

Lexend (Primary)

Fallbacks:

Outfit

Manrope

Type Scale
Usage	Weight	Size
Screen Title	Semibold	22–24
Section Header	Medium	18
Card Title	Medium	16
Body	Regular	14
Caption	Regular	12
Discount / Price	Semibold	16–18

❌ Do not mix multiple font families
❌ No ultra-bold or ultra-thin weights

6️⃣ Theme Architecture (Flutter)
Required Structure
lib/
 └── theme/
     ├── app_colors.dart
     ├── app_text_styles.dart
     ├── app_spacing.dart
     ├── app_theme.dart
     └── theme_provider.dart

Rules

All colors → AppColors

All spacing → AppSpacing

All text styles → AppTextStyles

All widgets must consume Theme.of(context)

7️⃣ Dark Mode
Implementation

Enable isDarkMode in ThemeProvider

Use same tokens with dark variants

No separate layouts for dark mode

Dark Mode Design Rules

No pure black

Prefer translucency

Cards use blurred surfaces

Shadows replaced with subtle glow

8️⃣ Component Redesign (Drop-In Replacement)
🧱 DiscountBuddyCard

Replaces: Existing restaurant / deal cards
Does NOT change: Data source or binding

Design Specs

Radius: 20px

Shadow: Soft layered elevation

Image: Top aligned, edge-to-edge

Gradient overlay at bottom only

Discount badge:

Pill shape

Indigo → Violet gradient

Text: “SAVE ₹XXX”

🔘 Buttons
Primary Button

Gradient background (Indigo → Violet)

Height: 52px

Radius: 14px

Press animation (scale 0.98)

Secondary Button

Transparent

Indigo border

Text-only emphasis

❌ Do not use default ElevatedButton styles

9️⃣ Navigation (Same Flow, New Look)
Bottom Navigation

Custom floating container

Slight blur / translucency

Icons always visible

Labels visible only when active

Active tab glow animation

⚠️ Tabs and routes remain unchanged

🔟 Screen-Level Guidelines
Home Screen

Preserve section order and API calls

Replace horizontal lists with:

Feed-style vertical sections

2-column grids where applicable

No new data sources

Restaurant Detail Page

Same API binding

New visual hierarchy:

Hero image

Floating info card

Clear CTA placement

Improve spacing & typography only

Profile / Edit Profile

Replace form styling

Improve spacing

No field changes

No validation changes

1️⃣1️⃣ Motion & Micro-Interactions

Mandatory:

Card entrance animation

Button press feedback

Tab switch animation

Skeleton loaders

Forbidden:

Excessive Lottie usage

Long blocking animations

1️⃣2️⃣ Assets & Icons

Replace emoji/hardcoded strings

Use centralized asset registry

Icons must follow consistent stroke weight

Prefer outlined icons with filled active states

1️⃣3️⃣ Cleanup Checklist (Mandatory)

 Remove all hardcoded hex colors

 Remove Colors.green, Colors.yellow

 Replace all ad-hoc shadows

 Ensure dark mode parity

 Verify no API contracts changed

 Verify navigation unchanged

1️⃣4️⃣ Success Criteria

Redesign is successful if:

App no longer visually resembles NeoTaste

All existing flows work without regression

Dark mode works across all screens

UI feels premium, confident, and modern

No backend developer complains

🧠 Final Reminder

This is not a redesign to look fancy.
This is a strategic de-cloning of your product identity.

If someone suggests:

“Let’s also tweak the API while we’re here”

The answer is NO.