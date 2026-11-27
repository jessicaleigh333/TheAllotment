# Multi-level greenhouse build study

Prototype for issue #34 and [the approved concept in PR #22](https://github.com/jessicaleigh333/TheAllotment/pull/22). The architectural image shows a central arched gable entrance, long-side masonry bays, green glazing frames and a partial upper level. The prototype uses the clean architectural sheet as the source of design intent. Measurements are design targets.

| View | Proposed geometry |
| --- | --- |
| Ground plan | 7.32 m across X and 10.97 m along Z, origin at the center of the finished floor. Front entrance centered on the negative-Z gable, 1.8 m clear. Stair in the rear half, leaving the center open. |
| Front elevation | Ridge 7.32 m. Eaves approximately 5.21 m at a 30° pitch across the 3.66 m half-span. Lower cream bay division at 3.05 m. |
| Side elevation | Four 2.74 m structural bays along the length, 5.21 m eaves, dark green rafters and pane frames. |
| Section | Upper floor 3.24 m with 0.19 m deck depth and 3.05 m nominal clearance under the slab. Upper walkable edge is inset 0.55 m from the eave. The roof is 5.52 m high at that line, leaving about 2.14 m after a 0.14 m framing allowance. |
| Stair and landing | Two 1.20 m wide flights of 10 risers at 0.162 m. Each flight has nine 0.28 m goings and a 2.52 m run. The quarter-turn has a 1.20 m landing. Collision uses continuous ramps with short level transitions at the landings. |
| Rails and thresholds | 1.05 m rails at exposed upper edges. Ground entry uses the floor datum, with foundation depth below it. The preview reserves the central void and omits the stair-side upper wing until headroom and turning are tested. |

## Preview scope

Open `staging/greenhouse_atrium_study.tscn` in Godot. This is a structural preview with ground, stair and upper-deck collision. The sky-facing cover and glazing are visual. Confirm the owner-approved acquisition route, test the in-garden camera and clearance through the walking controls, author finalized glazing/door/thumbnail modules, and extract the stable ID through the existing catalog pipeline before publishing a playable Shop item.

The proposed ID `greenhouse_atrium_multilevel_01` is absent from the existing runtime catalog. The draft has no pricing or gameplay publication.

## Garden 01 Market draft

The #42 prototype offers a single atrium for 450 Runes, a provisional balance value. Open Shop → Decor → Greenhouse atrium, buy one, then choose Place in Garden 01. A purchase deducts Runes and adds one atrium in the same save operation. Placement requires an owned atrium and consumes it. Returning the atrium preserves ownership and leaves the Rune balance alone.

The prototype uses a 6.60 m conservative footprint radius. The existing placement guard adds 0.20 m and checks 16 perimeter samples against a 0.06 m height tolerance and protected routes. The building stays on the ground in Garden 01. The stable catalog ID is `greenhouse_atrium_multilevel_01`. The catalog extracts the thumbnail, dimensions, collision and effective Rune price from the game.

Godot automation bought and placed the draft atrium, walked through the entry and up both flights, checked the rail, saved and reopened the placed object, retrieved it, and checked that an insufficient balance cannot buy another. The [Garden 01 render](../ai-handoff/evidence/greenhouse-market-42/garden.png) shows the draft masonry arches, frame, panes and accessible entry. The final door and material treatment, owner visual review, price tuning, and a manual camera pass in the live garden remain open.
