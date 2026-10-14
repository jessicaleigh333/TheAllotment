# Third-party asset credits

This file records external resources introduced for the gardener texture and lighting pass on 2026-10-14. Original game code, authored clothing/hair and hand-authored garden artwork are separate from these resources; any derived character anatomy is credited below. No reference-sheet image was downloaded or used as a model texture.

## Ready-to-copy game credits

> Outdoor image-based lighting: **Spruit Sunrise**, HDRI Haven / Poly Haven, [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/). [Source](https://polyhaven.com/a/spruit_sunrise). Distributed HDRI obtained from the official three.js examples repository.
>
> Woven cloth material detail: **Sheen Cloth**, Microsoft (2020), [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/). [Source](https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/SheenCloth). Only the small reusable texture maps are used; the sample model is not included.
>
> Character anatomy foundation: **MakeHuman hm08 base mesh**, Data Collection AB, Joel Palmius and Jonas Hauquier (2020), [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/). [Source](https://github.com/makehumancommunity/makehuman/blob/master/makehuman/data/3dobjs/base.obj). Head/neck geometry is adapted for the garden character; the original source is retained separately.

CC0 does not require attribution; these credits are retained at the owner's request. Downloaded source resources are recorded in the manifest below. The avatar documentation records their final integration.

## Resource records

### Spruit Sunrise HDRI

- Provider: HDRI Haven, now Poly Haven. The individual photographer was not independently confirmed during this pass, so the provider is credited rather than guessing a name.
- Primary asset page: <https://polyhaven.com/a/spruit_sunrise>.
- Actual download: <https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/textures/equirectangular/spruit_sunrise_1k.hdr>.
- Official distribution file record: <https://api.github.com/repos/mrdoob/three.js/contents/examples/textures/equirectangular/spruit_sunrise_1k.hdr?ref=dev>; Git blob SHA `8897536c654c45f201b4661728ebb2c786280f80`.
- License: CC0 1.0 Universal; canonical legal text <https://creativecommons.org/publicdomain/zero/1.0/legalcode>.
- Primary license evidence: Poly Haven's own website source, [asset license declaration](https://github.com/Poly-Haven/polyhaven.com/blob/master/public/locales/en/license.json) and [license page](https://github.com/Poly-Haven/polyhaven.com/blob/master/pages/license.tsx). The declaration states that all HDRIs/textures/models are CC0, commercial use and redistribution are permitted, and credit is appreciated but not required.
- Cross-check: Google's official [model-viewer attributions](https://github.com/google/model-viewer/blob/master/packages/shared-assets/ATTRIBUTIONS.md) explicitly attributes Spruit Sunrise to HDRI Haven under CC0.
- Local file: `assets/third_party/poly_haven/spruit_sunrise/spruit_sunrise_1k.hdr` (1,500,948 bytes).
- SHA-256: `38199a31e945906f6778431e989256a92d9d78b0cfc0f902accad9f5244bf50f`.
- Download date: 2026-10-14 UTC. File unmodified. Godot generates its own import cache and filtered sky/radiance maps; those do not replace this original.
- Use: restrained outdoor image-based portrait illumination. It is not a replacement for the game's authored courtyard geometry.

### Microsoft Sheen Cloth detail maps

- Author and rights holder: Microsoft, 2020, confirmed by the model's README and metadata.
- Official source: <https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/SheenCloth>.
- Asset license: CC0-1.0 for the model-associated text, image and binary files, declared by [LICENSE.md](https://github.com/KhronosGroup/glTF-Sample-Assets/blob/main/Models/SheenCloth/LICENSE.md).
- The 256 × 256 maps are authored as tileable technical fabric. The normal and packed ORM maps provide woven detail; the game can keep its own botanical colors and embroidery. The source sample's geometry is not downloaded.
- ORM channels: red ambient occlusion, green roughness, blue metallic. Normal data follows the glTF tangent-space convention. Use data/linear sampling for normal and ORM; use sRGB only for a base-color map. Do not apply the sample's baked cloth AO to the character's unrelated UVs.
- Original files, URLs, hashes and any derived-map changes are in `assets/third_party/manifest.json`.
- Upstream metadocumentation (LICENSE/README/metadata) has its own **CC-BY-4.0** declaration. Credit for the preserved, unmodified upstream documentation: **KhronosGroup glTF-Sample-Assets contributors / Microsoft**, [Sheen Cloth documentation](https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/SheenCloth), [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). This documentation license does not change the CC0 texture license.

### MakeHuman hm08 anatomy source

- Rights holders named in the original OBJ header: Data Collection AB, Joel Palmius and Jonas Hauquier (2020).
- Official source: <https://github.com/makehumancommunity/makehuman/blob/master/makehuman/data/3dobjs/base.obj>; Git blob SHA `d26635e9326e3cca30778fd7b9c00062b03cce09`.
- The OBJ header explicitly states that this asset was released under CC0 in September 2020. The project's [LICENSE.md, section C](https://github.com/makehumancommunity/makehuman/blob/master/LICENSE.md) explicitly includes the base mesh, and [LICENSE.ASSETS.md](https://github.com/makehumancommunity/makehuman/blob/master/LICENSE.ASSETS.md) provides the full CC0 legal text.
- The MakeHuman application's source-code license is separate. No MakeHuman application code or UI icons are included; this record concerns only its CC0 geometry asset.
- Original, unchanged source: `assets/third_party/makehuman_head/source/base.obj`, excluded from Godot's runtime importer with `.gdignore`.
- SHA-256: `8e761e6624b8f54536409135d1636da63b32486a90d4897f84e121d144f6fb4c`.
- Download date: 2026-10-14 UTC. The original source is preserved in full; the character asset adapts selected head/neck geometry, fitting it to the existing rig and storybook proportions. Clothes, hat and hair remain separately authored.
- Unmodified primary license statements are retained under `assets/third_party/makehuman_head/evidence/`.

## Evidence and future additions

`assets/third_party/` retains source/license evidence and a machine-readable download manifest. Legal-code snapshots are taken from the SPDX license-list-data repository and link to the canonical Creative Commons URLs. No signup, subscription or purchase was used. Do not assume a resource is reusable simply because it is described as free: record its author, exact license, source, original checksum and modifications here before integration.
