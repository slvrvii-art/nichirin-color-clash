# Nichirin: Color Clash

The approved game is an English-only, offline 2D Demon Slayer-themed trading card battler in the initialized Godot trading-card project. Keep source ownership in `scripts/card_game.gd` (simulation, presentation, input and persistence), `scripts/card_database.gd` (catalog), `scripts/battle_layout.gd` (board geometry), and `scripts/boot.gd` (startup). Preserve bundled fonts, licenses, runtime adapters and managed export pipeline.

## Implementation

Keep the current 51-card catalog: 39 fighter cards, 4 Support cards and 8 Item cards. Fighter editions are Normal or SURGE; there are no extra rarity-print fighter duplicates. Supports are limited to one per player's turn; any number of Items may be used that turn. Keep the strict 20-card deck, two-copy-per-catalog-card limit, color filters, selectable basic/full-art artwork and major alternate illustrations.

Retain Red, Blue, Yellow, Green, Purple, Pink and White Color Types, one generated Color Energy and one manual attachment per turn, one active fighter and exactly three bench spaces per side. Items, Supports, abilities and moves resolve through authoritative legality, effect and targeting helpers shared by player and AI. SURGE knockouts award two points; the first side to three points wins.

Apply Sleep, Poison, Burn and Paralysis only as defined effects on moves/abilities. Sleep blocks active attacks and retreat until a heads result on its controller's turn-start coin check clears it; tails leaves it. Poison deals 10 damage when its controller begins a turn and persists while active. Burn deals 20 at turn start, then its controller flips a coin; heads clears Burn, tails leaves it. Poison, Burn and Paralysis clear when that affected fighter retreats or a status-curing Item/Support resolves. Paralysis requires a pre-attack coin flip; heads permits damage and attack effects, while tails does zero damage and causes no attack effect. Statuses are visible, are conveyed in the How to Play rules and cannot linger on a discarded knockout.

Install the user's supplied slash GIF as the attack-animation source, preserve the original asset, render its keyed transparent frame sequence once per attack, and keep damage and turn-change feedback distinct. Respect reduced-motion settings. Keep AI actions valid for Item/Support limits, statuses, cards, Energy and attacks.

Save deck/presentation preferences and match records locally through the atomic JSON helper; migrate old fighter IDs to the corresponding Normal/SURGE cards while keeping a legal deck after migration.

## Utility-card effects

Implement utility selection in the shared battle controller so player and AI effects resolve legally. Corps Intelligence makes the opponent choose (or the local AI choose) a replacement Active Fighter from their Bench. Urokodaki's Lesson selects a Blue fighter in play and flips until tails, attaching one Blue Energy per heads. Ubuyashiki's Guidance draws 2. Kasugai Crow's Message is an Item that fetches a random Normal or standalone fighter from the deck. Hisa's Care clears statuses from the active fighter. Kakushi Retrieval is an Item: select a Fighter in hand, exchange it with a random Fighter from the deck and shuffle the deck. Swordsmith's Gift reveals the top deck card and lets the player keep the order or shuffle; the AI makes a deterministic legal choice. Remove Final Selection, Total Concentration, Butterfly Mansion and Hashira Training, then update deck recovery, catalog counts and tests.

## Setup and active-fighter transitions

After both shuffled opening hands are dealt, each side must start with an eligible Normal or standalone SURGE fighter chosen from that hand. The player chooses through the battle UI; the AI chooses from its own hand. Do not begin the first turn until the player confirms. If active damage Knocks Out a fighter while its controller has bench cards, prompt that controller to choose the replacement; resolve the AI's choice automatically and defer turn advancement until a human replacement is selected. Keep existing hand fallback and terminal conditions when no bench fighter can replace a knockout. Track own turns per side: paired SURGE Boosts require at least the owner's second turn and cannot happen on the Normal's play turn except for an explicit same-turn card-effect override; standalone SURGE cards remain normally playable.

Route every coin result through the shared coin helper and display each with a queued, brief Nichirin/sun-crest flip overlay. Use the same coin for random first-player selection; separate outcome calculation from presentation so tests and game logic remain deterministic, and respect reduced-motion settings.

## Project structure

- `scripts/card_game.gd`: hub, collection, deck builder, battle state, AI, card plays, turns, statuses, targeting, animations, persistence and UI.
- `scripts/card_database.gd`: current 39 fighter cards, 4 Support cards, 8 Item cards, their effects, starter decks and compatibility mapping.
- `scripts/coin_flip_animation.gd`: non-blocking, queued, reduced-motion-aware Nichirin coin animation and Heads/Tails display.
- `scripts/battle_layout.gd`: board geometry and safe-canvas placement.
- `scripts/card_face.gd`: Fighter/Support/Item face presentation, Normal/SURGE markers and selectable artwork.
- `assets/interface/attack_slash_frames.tres` plus supplied GIF-derived frames: one-shot attack animation; untouched source under `source-art/`.
- `test/` and `scripts/smoke_test.gd`: bounded deck, card-type, status, attack, AI and rendered behavior checks.
- `assets/fighters`, `assets/support`, `assets/interface`, `assets/share`, `web/` and `scenes/`: themed art, identity, loader and project scenes.

## Design

Selected style: Taisho-era collector's cabinet, with midnight navy, warm ivory live text, muted gold borders and vermilion actions. Keep the battle board quiet, off-center and spacious with a left navigation rail and right contextual panel. Retain the sunrise sword crest, geometric card borders and bundled body/display fonts.

Use the supplied slash GIF as the attack strike, smoothly keyed so its dark background is transparent over the board. The defender separately shakes and reddens, with floating damage numbers. Show compact legible status pills and turn-start coin outcomes. Turn changes retain their red/gold banner. Reduced-motion mode keeps the GIF cue brief and damage/status states visible.
