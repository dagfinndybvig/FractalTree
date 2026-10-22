# TODO

Remaining work, in order. Done items move to the git log, not here.

## F-Droid submission

- [ ] Fork `gitlab.com/fdroid/fdroiddata` (needs a GitLab account)
- [ ] Copy `fdroid/metadata/io.github.dagfinndybvig.fractaltree.yml` into the fork's `metadata/`
- [ ] Open a merge request toward fdroiddata; respond to reviewer questions
- [ ] Expected review topic: prebuilt jars in `android/app/libs/` (Processing core, Sound, JSyn — all LGPL, provenance in ANDROID.md). Be ready to document provenance or, if asked, build them from source in the recipe.
- [ ] After merge: watch the F-Droid build cycle, confirm their build installs and runs (it will be signed with F-Droid's key — a one-time reinstall for anyone coming from our APK)

## Distribution hygiene

- [ ] Remove the old `processing.test.treesketch` app from your phone (v1.2.1-alpha installs alongside it as a separate entry)
- [ ] Share the Latest release link with friends

## Possible later (no commitments)

- [ ] Meditative tuning: longer chime decay, slower wind cycle, optional session timer
- [ ] Icon glyph refinements (regenerate with the PIL script; palette matches the sketch)
- [ ] Second sketch → reuse the `android/` gradle template as a per-sketch pattern
