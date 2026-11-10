# Local saved profiles

Title-screen Login chooses a saved device profile; Create Account creates one with a 1–24-character display name. The first successful profile enters the playable garden directly, without the old account/terms/code preview. Return to title allows selecting another profile.

Profiles are ordinary local save files, not an encrypted credential vault or online account system. No email, password, legal consent, account service, multiplayer identity or garden ownership is created. Names are unique ignoring case, with up to 24 profiles. IDs are random hexadecimal strings rather than user-supplied file paths.

The index is written through a temporary file to `user://profiles/index.json`. Malformed indexes are not overwritten by profile creation. Avatar appearance, landscaping, favorites and the market use `user://profiles/<id>/...`. Explicit save paths used by existing tests/workshops still work. The first local profile copies any existing legacy avatar, market and ground-cover JSON saves; original legacy files are retained. Subsequent profiles begin with separate empty saves/default appearance. The existing garden remains the explicitly local Garden 01 demo, and players still save landscaping using the editor's Save control. The subsequent local market feature adds saved backpack counts and purchases; profile isolation does not add player-position persistence or account ownership.

Title sound/calendar settings remain device-wide. File saves stay on the computer where the game runs; GitHub does not sync these player files. No profile data is included in source commits or distribution ZIPs.

Verification covers name validation, duplicate rejection, persistent selection, malformed index preservation, first-profile legacy copy, separate appearance/landscaping paths and the title-to-garden-to-title flow. Use a fresh isolated XDG_DATA_HOME when running tests/verify_local_profiles.gd and tests/verify_profile_entry.gd.
