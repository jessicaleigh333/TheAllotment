# Original storybook gardener

Modular Blender character for The Allotment. Its continuous head/neck anatomy is adapted from the CC0 MakeHuman hm08 mesh; clothing, hair, hat and garden accessories are authored for the game. See the root CREDITS.md. Layered sage garden dress over an ivory underskirt, lace-edged puff sleeves, corset lacing, floral straw hat, leather satchel, wrist cuffs and garden belt/pouch, pendant, embroidered hem, tall laced boots, four hair variants, alternate trousers and apron. Softly stylized proportions; artwork pending owner review.

- `gardener.glb`: engine-ready rig, modular meshes, face morphs and Idle/Walk animation clips.
- `gardener_visual.tscn` / `.gd`: Godot appearance/animation wrapper.
- `fabric.gdshader`: recolorable linen dye variation, raised botanical embroidery and two-sided cloth.
- `hair.gdshader`: filtered painted strand and normal maps on UV-mapped waves.
- `leather.gdshader` / `straw.gdshader`: worn grain and woven straw maps, including a solid two-sided brim.
- `skin.gdshader` / `iris.gdshader`: soft complexion masks, painterly skin variation and iris fibres.
- `textures/`: shared original PNG detail, normal, roughness and embroidery maps.
- `source/build_surface_textures.py` / `build_face_textures.py`: reproducible texture authoring scripts; the texture README explains dependencies and packed channels.
- `source/gardener.blend`: editable Blender scene, materials, rig, shape keys and actions.
- `source/build_gardener.py`: reproducible authoring script. Run with Blender 4.3+: `blender --background --python source/build_gardener.py`. The script writes the blend/GLB beside itself using its own path. Reimport the GLB in Godot afterward.
- `source/.gdignore`: excludes authoring sources from Godot's automatic Blender importer.

The current asset has 44 modular mesh parts and approximately 124,000 polygons, including hidden options. Only selected variants are shown at runtime. One skeleton and reusable material/shader roles support expansion; production topology, LOD, more varied hair/body/wardrobe and animation refinements remain future work. No disconnected static preview substitutes are used for gameplay.

The supplied romantic gardener sheet guides the latest refinement: softer almond eyes, shaped jaw/continuous nose, layered clothing, fitted corset, wavy hair and practical leather details. This is an original editable prototype, not an exact reconstruction of the reference. The first texture polish pass is now integrated in Godot: dyed linen, botanical thread relief, hair strands, matte worn leather, straw weave, soft complexion and iris detail. Upper arms and gathered sleeves are slimmer; fuller cheeks, a shorter chin and a gentle closed smile provide a softer storybook face. Final sculpt refinements, facial expression blend shapes, production LOD and the full outfit variants remain future work. Tall boots retain calf/foot weights when modular meshes are joined.

The Blender file retains editable geometry, UVs, rig and named material roles. The Godot wrapper supplies the runtime texture maps/shaders so all player colors remain independent. Portrait UVs explicitly account for Blender-to-glTF V flipping. Small facial parts use normal shading without separate cast shadows, avoiding harsh marks on the face while the main character still casts a world shadow.

The revised sunhat has an oval, solid thin brim with a rolled edge, a rounded crown with a fitted lower wall, a narrow ribbon and varied flowers attached at the band. A small unified tilt moves brim, crown, ribbon and flowers together. Straw texture contrast is restrained, and redundant raised concentric rings were removed.

The latest reference pass uses a continuous anatomical head with fitted socket eyes, sculpted lips/nose/ears and corrective face/eye morphs. Hair now has a fitted scalp, asymmetrical flattened waves, tapered ends and corrected wrap UVs. CC0 Microsoft woven normal/ORM detail supplements the original linen/embroidery. The Poly Haven sunrise HDRI supplies portrait and neighborhood ambient/reflection lighting. Primary licenses and exact original-file hashes are in CREDITS.md and assets/third_party/manifest.json.
