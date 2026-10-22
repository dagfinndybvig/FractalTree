# TODO

Remaining work, in order. Done items move to the git log, not here.

## F-Droid submission (next step — tooling ready)

State: GitLab account exists (free tier). `glab` 1.124.0 is installed at
`%LOCALAPPDATA%\Programs\glab\glab.exe`. A personal access token with
api + write_repository scopes is stored as `GITLAB_TOKEN` in
`~/.vibe/.env` (loaded into the environment at Vibe startup; never commit
or print it). Revoke the token at
https://gitlab.com/-/user_settings/personal_access_tokens once the MR is
merged.

- [ ] Verify auth: `glab auth status --hostname gitlab.com` (needs a Vibe
  restart after the .env edit, so the token is in the environment)
- [ ] Fork `gitlab.com/fdroid/fdroiddata` (`glab repo fork fdroid/fdroiddata`)
- [ ] Commit `fdroid/metadata/io.github.dagfinndybvig.fractaltree.yml` to the
  fork's `metadata/` on a branch and push
- [ ] Open a merge request toward fdroiddata (`glab mr create`); respond to
  reviewer questions
- [ ] Expected review topic: prebuilt jars in `android/app/libs/` (Processing core, Sound, JSyn — all LGPL, provenance in ANDROID.md). Be ready to document provenance or, if asked, build them from source in the recipe.
- [ ] After merge: watch the F-Droid build cycle, confirm their build installs and runs (it will be signed with F-Droid's key — a one-time reinstall for anyone coming from our APK)
- [ ] Revoke the GitLab token

## Distribution hygiene

- [ ] Remove the old `processing.test.treesketch` app from your phone (v1.2.1-alpha installs alongside it as a separate entry)
- [ ] Share the Latest release link with friends

## Possible later (no commitments)

- [ ] Meditative tuning: longer chime decay, slower wind cycle, optional session timer
- [ ] Icon glyph refinements (regenerate with the PIL script; palette matches the sketch)
- [ ] Second sketch → reuse the `android/` gradle template as a per-sketch pattern
