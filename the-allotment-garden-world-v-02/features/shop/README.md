# Garden market

The Shop side button opens the full-screen French garden market. It uses new market art and an illustrated item atlas inspired by the owner's supplied reference images. The interface is composed of live Godot controls, not a flattened screenshot. Artwork is ready for visual review.

Browse All, Featured, Plants, Decor, Avatar, Tools, Seeds or Pinned. Search common or botanical names; Owned only includes items in the bag or placed in the garden. The Market, Backpack and Botanical catalog tabs share a collection. Details include a picture, care notes for plants, price, bag count and actions. Inspect 3D model opens an orbiting prototype mesh preview.

The starter collection has 16 entries: six mature plant clumps, six decor items, a flower-trimmed hat, a decorative watering can and two unavailable seed previews. Six plants, six decor items and the watering can can be placed; the hat equips the existing avatar option. Seed growing is not implemented, so seed purchases are disabled and never spend Runes. Item illustrations are richer than the deliberately simple 3D prototype models, which are labeled accordingly. No production-quality mesh integration is claimed.

Each local profile begins with 1,250 prototype Runes. Buy spends the displayed price and adds one bag item in one atomic local-save snapshot. There is no real-money checkout, online economy or earning/reward system in this increment. Basic existing gardening tools remain free. Insufficient funds, unavailable items and unreadable/write-failed saves do not spend currency. The common-item row holds up to six pinned items.

From an owned item choose Plant/Place in garden, then click an open position inside the local demo Garden 01. R rotates; WASD pans; wheel zooms; Done/Escape cancels. Bounds, existing protected structures, shared hedge edges and purchased-object overlap are checked. Placement consumes one bag item and persists it; reopening the world restores saved models. Cancel does not consume an item. The Backpack can return placed objects to the bag without a refund or duplication. The existing demo scope is not a multiplayer ownership system.

Storage: user://profiles/<id>/market.json for a selected local profile; direct scene/legacy runs use user://market.json. No player save data is committed. Files include balance, bag counts, six favorite slots and placements. A malformed save is preserved and purchasing is blocked. Bounded counts and schema checks guard load; temporary-file replacement commits the complete state.

Preview: F5, enter a local profile, then Shop. Buy a Rose bush, switch to Backpack and choose Plant in garden. For a standalone visual scene use features/shop/screen.tscn; placement is disabled without a world.

Validation: tests/verify_market.gd uses a fresh isolated XDG_DATA_HOME and covers transactions, persistence, profile isolation, failed purchases, corrupt-save preservation, filters, Latin-name search, 3D previews, placement constraints, consumption/reload/retrieval and HUD wiring. ui/verify_hud.gd covers all 12 destinations and Escape. Rendered Market, Backpack and Botanical catalog at 1280×720 with Godot 4.6.3 OpenGL Compatibility. The project targets 4.7; owner visual review remains pending.
