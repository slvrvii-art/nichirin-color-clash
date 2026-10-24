# Nichirin: Color Clash outcomes

- [x] Card catalogue: 150 unique cards. Each of 24 characters has exactly one Normal fighter and one SURGE fighter (48 fighters); 102 utility cards are split into 53 Support and 49 Item cards. Full/basic art selection and featured alternate art remain.
- [x] Decks and utility plays: Exactly 20 cards per deck, at most two copies of each card. Support usable once per turn; multiple Items allowed per turn. Older saved fighter IDs migrate to the matching Normal/SURGE cards, and the deck stays legal.
- [x] Color and board rules: Red, Blue, Yellow, Green, Purple, Pink and White Color Types; one generated Color Energy and one Energy attachment per turn; one active fighter and three bench spots; SURGE knockout awards 2 points.
- [x] Status effects: Sleep, Poison, Burn and Paralysis on selected attacks, with turn-start coin flips, damage ticks, retreat clears, curing Items/Supports, status pills, logged coin results and clearing on knockout.
- [x] Attack animation: User-supplied 18-frame slash GIF plays once per attack with a transparent background; damage feedback stays separate; original GIF preserved in source-art.
- [x] Existing battle flow: Muzan's once-per-turn Blood Dominion, auto turn end on attack, explicit End Turn, turn banner, deck limit, bench capacity and AI.
- [x] Updated delivery: Tests and native renders pass; checkpoint b0a2bf3 saved and published.

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
- [x] Catalog reduced to 61 cards: 39 fighters, 12 Support, 10 Item; generated filler cards removed.
- [x] Duplicate utility effects replaced with distinct ones (draw-to-5, forced opponent switch, free retreat, bench heal, cleanse+draw, boost+guard).
- [x] Utility effect text wraps on large cards and trims on small cards.

## Rounded stats
- [x] All fighter HP and attack damage rounded up to the nearest 10 (no values ending in 5).

## Kakushi Stretcher
- [x] Item effect: during this turn, your active fighter retreat cost is 1 less.

## Tamayo's Remedy update
- [x] Item effect is exactly “Restore 20 HP to your active fighter”; it heals the active fighter by 20 and does not clear status conditions.
