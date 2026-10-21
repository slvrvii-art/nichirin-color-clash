# Nichirin: Color Clash

The approved game is an English-only, offline 2D Demon Slayer-themed trading card battler in the initialized Godot trading-card project. Keep source ownership in `scripts/card_game.gd` (simulation, presentation, input and persistence), `scripts/card_database.gd` (catalog), `scripts/battle_layout.gd` (board geometry), and `scripts/boot.gd` (startup). Preserve bundled fonts, licenses, runtime adapters and managed export pipeline.

## Implementation

Keep the 150-card minimum while removing the six-form rarity ladder from fighter cards: the 24 character fighters each have exactly one Normal and one SURGE version, for 48 fighters. There are no extra rarity-print fighter duplicates. The remaining 102 catalog entries are utility cards divided between Support and Item, including the current support pool. Supports are limited to one per player's turn; any number of Items may be used that turn. Keep the strict 20-card deck, two-copy-per-catalog-card limit, color filters, selectable basic/full-art artwork and major alternate illustrations.

Retain Red, Blue, Yellow, Green, Purple, Pink and White Color Types, one generated Color Energy and one manual attachment per turn, one active fighter and exactly three bench spaces per side. Items, Supports, abilities and moves resolve through authoritative legality, effect and targeting helpers shared by player and AI. SURGE knockouts award two points; the first side to three points wins.

Apply Sleep, Poison, Burn and Paralysis only as defined effects on moves/abilities. Sleep blocks active attacks and retreat until a heads result on its controller's turn-start coin check clears it; tails leaves it. Poison deals 10 damage when its controller begins a turn and persists while active. Burn deals 20 at turn start, then its controller flips a coin; heads clears Burn, tails leaves it. Poison, Burn and Paralysis clear when that affected fighter retreats or a status-curing Item/Support resolves. Paralysis requires a pre-attack coin flip; heads permits damage and attack effects, while tails does zero damage and causes no attack effect. Statuses are visible, are conveyed in the How to Play rules and cannot linger on a discarded knockout.

Install the user's supplied slash GIF as the attack-animation source, preserve the original asset, render its keyed transparent frame sequence once per attack, and keep damage and turn-change feedback distinct. Respect reduced-motion settings. Keep AI actions valid for Item/Support limits, statuses, cards, Energy and attacks.

Save deck/presentation preferences and match records locally through the atomic JSON helper; migrate old fighter IDs to the corresponding Normal/SURGE cards while keeping a legal deck after migration.

## Project structure

- `scripts/card_game.gd`: hub, collection, deck builder, battle state, AI, card plays, turns, statuses, targeting, animations, persistence and UI.
- `scripts/card_database.gd`: 24 characters/48 fighter editions, 102 Support/Item effects, starter decks and compatibility mapping.
- `scripts/battle_layout.gd`: board geometry and safe-canvas placement.
- `scripts/card_face.gd`: Fighter/Support/Item face presentation, Normal/SURGE markers and selectable artwork.
- `assets/interface/attack_slash_frames.tres` plus supplied GIF-derived frames: one-shot attack animation; untouched source under `source-art/`.
- `test/` and `scripts/smoke_test.gd`: bounded deck, card-type, status, attack, AI and rendered behavior checks.
- `assets/fighters`, `assets/support`, `assets/interface`, `assets/share`, `web/` and `scenes/`: themed art, identity, loader and project scenes.

## Design

Selected style: Taisho-era collector's cabinet, with midnight navy, warm ivory live text, muted gold borders and vermilion actions. Keep the battle board quiet, off-center and spacious with a left navigation rail and right contextual panel. Retain the sunrise sword crest, geometric card borders and bundled body/display fonts.

Use the supplied slash GIF as the attack strike, smoothly keyed so its dark background is transparent over the board. The defender separately shakes and reddens, with floating damage numbers. Show compact legible status pills and turn-start coin outcomes. Turn changes retain their red/gold banner. Reduced-motion mode keeps the GIF cue brief and damage/status states visible.
