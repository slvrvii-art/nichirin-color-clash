# Nichirin: Color Clash outcomes

- [x] Card catalogue: 51 unique cards—39 fighters, 4 Support and 8 Item. Fighter editions are Normal or SURGE; full/basic art selection and featured alternate art remain.
- [x] Decks and utility plays: Exactly 20 cards per deck, at most two copies of each card. Support usable once per turn; multiple Items allowed per turn. Older saved fighter IDs migrate to the matching Normal/SURGE cards, and the deck stays legal.
- [x] Color and board rules: Red, Blue, Yellow, Green, Purple, Pink and White Color Types; one generated Color Energy and one Energy attachment per turn; one active fighter and three bench spots; SURGE knockout awards 2 points.
- [x] Status effects: Sleep, Poison, Burn and Paralysis on selected attacks, with turn-start coin flips, damage ticks, retreat clears, curing Items/Supports, status pills, logged coin results and clearing on knockout.
- [x] Attack animation: User-supplied 18-frame slash GIF plays once per attack with a transparent background; damage feedback stays separate; original GIF preserved in source-art.
- [x] Existing battle flow: Muzan's once-per-turn Blood Dominion, auto turn end on attack, explicit End Turn, turn banner, deck limit, bench capacity and AI.
- [x] Previous delivery: Checkpoint `12a3d97fecff4d23d720e309b67be53fe43d0301` passed the smoke, AI-match, managed and pack checks; it is published at https://nichirin-eakw5bhv.manus.game.

## Boost update
- [x] Normal fighters: basic art, one attack. SURGE fighters: full art.
- [x] Boost mechanic: SURGE cards with a Normal version must Boost onto it; standalone SURGE cards play directly.
- [x] Removed Muzan, Yoriichi, Kokushibo, Kanao, Gyomei, Doma, Sanemi and Obanai.
- [x] New fighters: Murata, Kyogai SURGE, Aoi Kanzaki, Susamaru (Normal + SURGE), Yahaba, Tanjiro (Hinokami Kagura) SURGE.
- [x] Gold metallic gradient SURGE wordmark in the Bungee font.
- [x] Tests, native renders and checkpoint.

## Rules update 2
- [x] Random first player (coin-flip banner).
- [x] No Energy attachment on the duel's first turn.
- [x] No Boost on the turn a fighter was played (card effects may override via boost_now).
- [x] Retreat cost: Normal 1 Energy, SURGE 2; once per turn; started from the active fighter.
- [x] Normal art fits inside its frame without clipping.

## UI update
- [x] Opponent cards in play open a detail view (live HP, Energy, status); the duel pauses while it is open.
- [x] Ability names shown on every card that has an ability.
- [x] Full-art SURGE cards no longer have dark translucent bands; text uses an outline instead.

## Utility cut
- [x] Catalog reduced to 51 cards: 39 fighters, 4 Support, 8 Item; generated filler cards removed.
- [x] Utility effects updated to the requested Recovery Breathing, Sunlight Charm, Tamayo's Remedy, Kakushi Stretcher and named-card actions.
- [x] Utility effect text wraps on large cards and trims on small cards.

## Rounded stats
- [x] All fighter HP and attack damage rounded up to the nearest 10 (no values ending in 5).

## Kakushi Stretcher
- [x] Item effect: during this turn, your active fighter retreat cost is 1 less.

## Tamayo's Remedy update
- [x] Item effect is exactly “Restore 20 HP to your active fighter”; it heals the active fighter by 20 and does not clear status conditions.

## Utility-effect update
- [x] Recovery Breathing: flip a coin; on heads, generate one Energy from the Energy Zone and attach it to the active fighter.
- [x] Sunlight Charm: “Your opponent shuffles their hand into their deck and draws 3 cards.”
- [x] Remove Wisteria Medicine, Aoi's Care, Protect the Innocent, Haganezuka's Resolve, Butterfly Poultice and Nichirin Polish from the catalog; update preset/saved deck handling, card counts, and tests accordingly.

## Utility card redesign
- [x] Corps Intelligence switches out the opponent's Active Fighter to the Bench; the opponent chooses the new Active Fighter (the AI selects its own replacement).
- [x] Urokodaki's Lesson lets you choose one of your Blue Color Type fighters, then flip until tails; for each heads, take one Blue Energy from your Energy Zone and attach it to that fighter.
- [x] Ubuyashiki's Guidance draws 2 cards.
- [x] Rename Kasugai Crow to Kasugai Crow's Message, make it an Item, and put one random Normal or standalone fighter from your deck into your hand.
- [x] Remove Final Selection, Total Concentration, Butterfly Mansion and Hashira Training.
- [x] Rename Wisteria Sanctuary to Hisa's Care; its effect clears all status conditions from your active fighter.
- [x] Make Kakushi Retrieval an Item; choose a fighter in your hand and swap it with a random fighter in your deck.
- [x] Swordsmith's Gift reveals the top card of your deck, then lets you choose whether to shuffle your deck.
- [x] Recalculate card counts, update preset/deck recovery behavior, show all effect text/choices in game, and verify the effects.
- [x] Updated delivery: Smoke and AI-match tests passed; `npm run check` and pack verification succeeded; the matching checkpoint and 51-card sharing metadata were confirmed and published.

## Battle setup and turn-choice update
- [x] Show a simple Demon Slayer/Nichirin-themed coin-flip animation and its Heads/Tails result every time a coin is flipped.
- [x] Before turns begin, each player chooses an eligible fighter from their opening hand for the Active spot; the opponent AI chooses from its own starting hand.
- [x] When an Active Fighter is Knocked Out and its player has benched fighters, let that player choose which benched fighter becomes Active; the AI chooses its own replacement.
- [x] A paired SURGE card can be Boosted only from its owner's second turn onward, and never on the turn its Normal fighter entered play, except where an existing explicit card effect overrides the same-turn restriction. Standalone SURGE cards remain directly playable.
- [x] Update the in-game turn guidance and verify random setup, both replacement paths, all coin-flip call sites, and Boost timing.
- [x] Updated delivery: Checkpoint `4fc23d5983a12092f8df061884540b249b175950` passed smoke, AI-match, managed and pack checks; it is published at [Nichirin: Color Clash](https://nichirin-eakw5bhv.manus.game).

## UI and asset performance refactor
- [x] Reuse the game UI root and pooled control/card-face nodes across renders; reset old state and signal connections so reused nodes show current data and do not trigger stale callbacks.
- [x] Start card-image loading with `ResourceLoader.load_threaded_request()`; deduplicate requests, update only still-matching live image nodes after completion, and avoid synchronous card-art loading during rendering.
- [x] Bound asynchronous image polling/cache work so it runs only while requests are pending and does not cause unbounded texture memory growth.
- [x] Remove eager preloads of unused legacy card-game art from `card_database.gd` while preserving legacy compatibility only if still referenced. Keep the required controller-script resource in `card_game.tscn`; remove no active scene dependency.


## Optimization follow-up
- [x] Build the 51-card catalog once on first access, index definitions by ID, recursively freeze cached definitions, and make deck validation perform direct indexed reads rather than rebuilding/copying the catalog per card. Keep mutable gameplay card instances isolated.
- [x] Load the active PackedScene through `ResourceLoader.load_threaded_request()` with throttled progress polling; preserve the current loading/retry experience and never call `load_threaded_get()` before the resource is ready.
- [x] Cap persisted JSON at 1 MiB and reject oversized save input/output while keeping valid primary/backup recovery intact.
- [x] Recycle pooled UI children without duplicated child-array snapshots or scanning every inherited Control signal; clear `OptionButton` entries before rebuilding filters.
- [x] Lazily cache normalized collection-search text and retain ascending catalog order, avoiding per-render string rebuilding/lowercasing and redundant sorting.

## Performance review follow-up
- [x] `_save()` returns its `Error`; the save wrapper records failures, retains pending/unsaved state, displays a retry notice, and only marks a match record saved after success.
- [x] `battle_layout.gd` uses viewport and safe-inset inputs; `card_game.gd` applies one fit transform and uses mapped Active/Bench zones, with one guarded viewport-resize subscription.
- [x] The `audio.muted` toggle applies to Godot's Master bus without overwriting bus volumes.
- [x] Godot 4.7.2 smoke, match, atomic JSON, safe-area, layout integration, save-failure/retry, and audio-mute assertions pass. Direct local probes load the tested font, shader, and SpriteFrames resources.
- [x] Replaced both collection/detail Add to Deck lambdas with bound void Callables; a regression emits the real buttons, verifies each adds one card within the 20-card cap, and the existing smoke test passes.
- [ ] Review non-failing UI cleanup warnings: one match run discarded a stale freed pooled Panel; the Add-to-Deck regression reported two ObjectDB references at shutdown (one RefCounted instance in verbose mode). All gameplay assertions passed.
- [ ] Managed packaging remains blocked: `npm run check` exits 1 because its frozen run cannot preload `res://assets/interface/attack_slash_frames.tres`, `res://assets/template/fonts/ui_regular.tres`, `ui_medium.tres`, and `display/card_title.tres`. A fresh no-argument `prepare-release` also failed its exported-PCK startup check on `ui_medium.tres`, `display/card_name.tres`, `Bungee-Regular.ttf`, and `surge_gold.gdshader`; asset reconciliation reported 168 tracked, 0 uploaded, and 0 restored. Direct Godot probes load every named resource from the local tree, and Bungee, Figtree, and ManusCC0 font bytes match `assets.lock.json`. The post-fix `preview:build` also failed on PCK preload errors and did not advance the preview generation, so the changed callback has only been verified natively. The previous `save-release` attempt stopped before committing. Do not save/push this pass until a supported snapshot-refresh path resolves the managed check.

## User-supplied artwork update
- [x] Applied the supplied PNG byte-for-byte to `assets/fighters/zenitsu_full.png` through the guarded asset-edit workflow; the lock digest/size match, and direct Godot threaded loading passed at 1080×1920.
- [x] Verified `zenitsu_surge` resolves to `res://assets/fighters/zenitsu_full.png`; the actual `CardFace` threaded loader loads the supplied 1080×1920 texture.
- [ ] Make the replacement visible in the managed Web preview: the served generation remains `2d84354f559e3c16d4dddf04de4b76449860c462d6113db0d4cc02cef4a09e33`. The latest `preview:build`, portable `npm run build`, and fresh `prepare-release` fail on frozen-Game-input resource preloads. The Zenitsu mapping and 23 referenced locked binary dependencies are verified locally; the required resource definitions/shader are tracked and the export preset uses `all_resources`. No supported project snapshot-sync operation is registered, so a provider-side frozen-input refresh is needed before rebuilding.


## Deck, Color Energy, and animation update
- [x] Deck builder supports up to 10 saved, independently selectable deck profiles. Each profile retains its own deck of at most 20 cards and its own Energy-color selection; users can create, select and delete profiles.
- [x] Each deck can select 1–3 Color Energy types from Red, Blue, Yellow, Green, Purple, Pink and White. One Energy color is selected at random from that profile's pool at turn start; the once-per-turn manual attachment rule remains.
- [x] White Color Type fighters treat attack and retreat costs as Colorless, payable with any attached Energy colors; attack legality, retreat payment and player-facing cost text use the same rule.
- [x] Coin-flip animation resolves before the related attack slash begins. Every Energy grant/attachment routes through the shared grant helper and can show a bounded flight to its target card, respecting reduced-motion settings.
- [x] Godot parser, focused deck/Energy test, smoke, match, Add-to-Deck, save-retry and atomic JSON checks pass; a stale pooled-node warning and test-only ObjectDB shutdown references remain noted above.
- [ ] Managed check, Web preview rebuild and checkpoint remain blocked by the frozen-PCK font/shader/resource preload failure recorded above; source-level tests do not update the served generation.

## GitHub source update — October 25, 2026

This repository update includes the current ten-deck builder, per-deck selection of one to three Color Energy types, White fighter Colorless costs, coin-before-attack sequencing, Energy-flight effects, related tests, and artwork edit history. Both selected Zenitsu image files are present and match the project source. All 168 locked asset files are present with matching checksums. The GitHub-specific self-contained asset ignore rules and independent GitHub artwork commits are preserved.

Native Godot 4.7.2 import, deck/Energy regression, smoke, Add-to-Deck callback, and save-failure/retry checks passed in an isolated checkout. The Add-to-Deck test still emitted one non-failing ObjectDB shutdown warning. This is a source backup only: no newer compiled PCK/WASM or Manus checkpoint was produced. Existing exported files remain historical and do not represent the latest source.

The managed check and preview build remain blocked by resource preload errors. A newer read-only diagnostic successfully loaded the named resources from an older retained PCK in an empty project directory; that PCK contains an older controller. Consequently, missing files in the current frozen input remain an unconfirmed explanation rather than an established root cause. The earlier instruction not to save/push refers to the managed release pipeline, not this explicitly requested GitHub source backup.
