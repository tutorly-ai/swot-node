# Maintaining `@tutorly-ai/swot-node`

This is a fork of [marvinschopf/swot-node](https://github.com/marvinschopf/swot-node),
repackaged under the `@tutorly-ai` npm scope. Its whole job is to bundle the
[JetBrains/swot](https://github.com/JetBrains/swot) dataset (vendored as the
`data/` git submodule) into an installable npm package. "Repackaging" =
**pull the latest dataset → bump version → publish.**

- **npm package:** https://www.npmjs.com/package/@tutorly-ai/swot-node (public)
- **GitHub repo:** https://github.com/tutorly-ai/swot-node
- **Dataset upstream:** https://github.com/JetBrains/swot (the `data/` submodule)

---

## TL;DR — repackage with the latest dataset

```sh
npm install                 # first time on a fresh clone (see "Fresh clone" below)

npm run update-data         # pull latest JetBrains/swot master into data/ and stage it
git commit -m "Update swot dataset to latest upstream"

npm version patch           # bumps version in package.json, commits, and tags
npm run release             # builds (tsc) + publishes to npm as public
git push --follow-tags      # push the commits + version tag to GitHub
```

That's the entire loop. The sections below explain each part and how to set up
the one-time pieces (the `.env` token).

---

## One-time setup

### 1. Fresh clone

The dataset lives in a git submodule, so clone with `--recurse-submodules`
(or initialise it after the fact):

```sh
git clone --recurse-submodules https://github.com/tutorly-ai/swot-node.git
cd swot-node
npm install

# If you already cloned without submodules:
git submodule update --init --remote data
```

### 2. Create the `.env` with an npm token

Publishing reads `NPM_TOKEN` from a local `.env` file (gitignored — never
committed). You need a token that can publish to the `@tutorly-ai` scope **and
bypass the org's two-factor requirement**, because `npm run release` runs
non-interactively.

**How to generate the token (this is the bit that's easy to forget):**

1. Log in to npmjs.com as a member of the **tutorly-ai** org.
2. Go to **Access Tokens** → https://www.npmjs.com/settings/~/tokens
   → **Generate New Token**.
3. Pick a token type that bypasses 2FA — either of these works:
   - **Granular Access Token** with:
     - Expiration: your choice (e.g. 90 days)
     - **Packages and scopes:** Read and write → scope `@tutorly-ai`
     - **Organizations:** Read and write → `tutorly-ai`
     - **Enable "bypass 2FA"** (required — without it publishing fails with
       `E403 ... bypass 2fa enabled is required`)
   - **OR a Classic → Automation token** (these bypass 2FA by design).
4. Copy the token (starts with `npm_…`) and put it in `.env`:

   ```sh
   echo 'NPM_TOKEN=npm_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' > .env
   ```

Granular tokens expire (e.g. 90 days). When `npm run release` starts failing
with `401 Unauthorized`, the token has expired — just regenerate it (step 2–4)
and overwrite `.env`.

> **Why `.env` + `.npmrc`?** npm does **not** read a `NPM_TOKEN` env var on its
> own. The committed `.npmrc` contains `//registry.npmjs.org/:_authToken=${NPM_TOKEN}`,
> which tells npm to substitute the token from the environment. The `release`
> script sources `.env` (`set -a && . ./.env`) so that variable is present when
> `npm publish` runs. The `.npmrc` holds no secret — only the `${NPM_TOKEN}`
> reference — so it's safe in the repo. The actual token stays in `.env`.

---

## How each script works

| Command              | What it does |
|----------------------|--------------|
| `npm run update-data`| Runs `scripts/update-data.sh`: pulls the latest commit from JetBrains/swot `master` into the `data/` submodule and `git add`s the new pointer. Prints the new dataset commit. Does **not** commit — you do that. |
| `npm version patch`  | Bumps the version in `package.json` (e.g. `2.0.1490` → `2.0.1491`), commits that change, and creates a matching git tag. Use `minor`/`major` if appropriate. |
| `npm run build`      | Compiles TypeScript (`src/`) to `dist/` via `tsc`. Run automatically by `release`. |
| `npm run release`    | `build` + sources `.env` for `NPM_TOKEN` + `npm publish`. Publishes **public** (set in `publishConfig.access`). |
| `npm test`           | Runs the mocha test suite. Worth running before a release. |

---

## Notes & gotchas

- **Public, not private.** `publishConfig.access` is `"public"`. Private
  packages require a paid npm org plan (`E402 Payment Required`), which this org
  isn't on. If you ever want it private, upgrade the org's billing at
  https://www.npmjs.com/settings/tutorly-ai/billing and change `access` to
  `"restricted"`.
- **The submodule tracks `master`.** `.gitmodules` points `data/` at
  `JetBrains/swot`; `--remote` (used by `update-data`) moves it to that repo's
  default branch tip.
- **Version scheme.** Upstream used `2.0.<n>` where `<n>` just increments.
  `npm version patch` keeps that going. You can't republish an existing version —
  always bump before `release`.
- **First fork artifact.** This was forked from `marvinschopf/swot-node`; the
  upstream chain is `leereilly/swot` → `JetBrains/swot` (dataset) and
  `marvinschopf/swot-node` (the Node wrapper). Only the dataset submodule needs
  routine updating.
