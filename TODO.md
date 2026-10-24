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
