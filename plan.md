# Nichirin: Color Clash

The approved game is an English-only, offline 2D Demon Slayer-themed trading card battler in the initialized Godot trading-card project. Keep source ownership in card_game.gd (simulation, presentation, input, persistence), card_database.gd (catalog), battle_layout.gd (board geometry), and boot.gd (startup). Preserve bundled fonts, source licenses, runtime adapters and managed export pipeline. Replace the starter's unrelated kitchen combat with active-card and three-bench-slot rules.

## Implementation

Build a 162-card catalog: 24 characters across six mechanically distinct forms (144 fighter cards), plus 18 Support cards. Include Common, Uncommon, Rare, Epic and Legendary rarities, SURGE variants, basic-art and full-art treatments, and independently illustrated alternate full art for major characters. Red, Blue, Yellow, Green, Purple, Pink and White are Color Types; a matching Color Energy is generated once each player turn and may be attached once. Twenty cards exactly are required to enter battle; never permit adding card 21. Limit two copies of a catalog card. Save deck, artwork preference, collection discoveries and match record locally with the template's atomic JSON helper.

The battle has one active fighter and three bench slots per side. Draw a five-card opening hand containing a fighter, place the opening fighter automatically, then draw once each turn. Play fighter cards to the bench, use at most one Support per turn, attach Color Energy to active or bench, and retreat once for one attached energy. Costs require matching color plus flexible energy. Active attacks resolve damage, knockouts and points, then end the turn automatically. Three knockout points win; SURGE knockouts grant two. An empty enemy board also wins. AI uses the same core legality functions. Offer explicit End Turn, rules/pause, victory/defeat and replay.

## Project structure

- scripts/card_game.gd: menu, battle, collection, deck builder, card preview, AI, persistence and user actions.
- scripts/card_database.gd: all 162 card definitions and art references.
- scripts/battle_layout.gd: 1440×900 safe fixed board geometry.
- scripts/card_face.gd: reusable live-text card component, basic/full art and rarity treatments.
- assets/fighters, assets/support, assets/interface, assets/share: game-specific generated artwork.
- web loading source and scenes/boot.tscn: original loader with real progress and retry.
- test/nichirin_rules_test.gd and native capture: bounded rules checks and rendered evidence.

## Design

Three considered styles: Taisho-era collector's cabinet (0.07), neon tournament broadcast (0.04), sumi-e paper tabletop (0.06). Selected: Taisho-era collector's cabinet.

A midnight navy collectible-card interface with warm ivory live text, muted gold hairline borders and vermilion actions. Broad illustrated cards carry the color accents; the board stays quiet and spacious. A thin left navigation rail and horizontal page headings create an off-center workspace, with a right-side contextual deck/attack panel. Signature motifs are a sunrise sword crest, fine geometric card borders and small monospaced catalog numbering. Use the bundled display/body font resources. The wordmark stacks NICHIRIN with a widely spaced COLOR CLASH subtitle, paired with a game-specific sword crest crop. Personality: precise, cinematic, collectible. Brand voice: 'Draw your blade.' and 'One strike. A new turn.'

Attacks lunge the active card and send a sweeping slash toward the opposing active card. Damage shakes and briefly reddens the target while a damage number rises. Turn changes sweep a gold/red banner across the board. Collection cards lift on hover; full-art SURGE cards shimmer with a gold border. A reduced-motion option keeps cues readable with short fades rather than travel.
