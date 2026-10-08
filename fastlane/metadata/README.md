# Store listing metadata

App store listing copy for **Picklog**, in English (`en-US`) and Brazilian Portuguese (`pt-BR`).

The layout follows the [fastlane](https://docs.fastlane.tools) convention for `supply` (Google Play) and `deliver` (App Store). Because both platforms live side by side under `android/` and `ios/`, **`deliver` must be pointed at the iOS folder explicitly** with `metadata_path: 'fastlane/metadata/ios'` — see [Running the upload](#running-the-upload).

> **All text here is DRAFT.** It needs the owner's review and approval before any store submission, and should be re-checked against the shipping build so it never describes a feature the app does not have.

## Layout

```
fastlane/metadata/
├── android/                  # Google Play (supply)
│   ├── en-US/
│   │   ├── title.txt
│   │   ├── short_description.txt
│   │   └── full_description.txt
│   └── pt-BR/                # same three files
└── ios/                      # App Store (deliver)
    ├── en-US/
    │   ├── name.txt
    │   ├── subtitle.txt
    │   ├── promotional_text.txt
    │   ├── description.txt
    │   └── keywords.txt
    └── pt-BR/                # same five files
```

## Running the upload

`deliver` (App Store) defaults its `metadata_path` to `fastlane/metadata/`, expecting locale folders (`en-US/`, `pt-BR/`) directly under it. Here that default path holds the `android/` and `ios/` split instead, so **`deliver` will not find the iOS copy unless you override `metadata_path` to point at `ios/`**. `supply` (Google Play) reads `fastlane/metadata/android/` by convention and needs no override.

```ruby
# Fastfile

platform :ios do
  lane :upload_metadata do
    deliver(
      metadata_path: "fastlane/metadata/ios",
      skip_screenshots: true,
      skip_binary_upload: true,
    )
  end
end

platform :android do
  lane :upload_metadata do
    supply(
      metadata_path: "fastlane/metadata/android",
      skip_upload_apk: true,
      skip_upload_aab: true,
      skip_upload_images: true,
      skip_upload_screenshots: true,
    )
  end
end
```

`supply`'s `metadata_path` already defaults to `fastlane/metadata/android`, so it is passed above only for symmetry. The `skip_*` flags upload copy only; drop them once screenshots and binaries are wired up.

## Character limits

| Store        | Field                | File                    | Limit  |
| ------------ | -------------------- | ----------------------- | ------ |
| Google Play  | Title                | `title.txt`             | 30     |
| Google Play  | Short description    | `short_description.txt` | 80     |
| Google Play  | Full description     | `full_description.txt`  | 4000   |
| App Store    | Name                 | `name.txt`              | 30     |
| App Store    | Subtitle             | `subtitle.txt`          | 30     |
| App Store    | Promotional text     | `promotional_text.txt`  | 170    |
| App Store    | Keywords (CSV)       | `keywords.txt`          | 100    |
| App Store    | Description          | `description.txt`       | 4000   |

The DRAFT markers at the bottom of the long descriptions are **not** part of the published copy. Remove them before submission (they keep the count well under the limit while drafting).

## Still TODO (owner-provided)

These are assets/decisions this PR intentionally does not cover:

- **Screenshots** (phone, tablet) and **feature graphic** (1024x500) — depends on branding (#15).
- **App icon** — depends on branding (#15).
- **Privacy policy URL** — link the published policy once available (Play Data safety + App Store privacy section). The app already exposes data export and account deletion (LGPD).
- **Content rating** questionnaire (Play) / age rating (App Store).
- **Data safety / privacy declarations** — declare data collection accurately. The app collects account email and uses optional Firebase Cloud Messaging for push (consent-gated).
- **Permission declarations** — the Android manifest currently requests `INTERNET` only. Declare any further runtime permissions (e.g. notifications) only if/when they are actually added.
- **Final copy approval** in both locales.

## Updating

Edit the `.txt` files in place; keep both locales in sync. Mirror any wording change in `android/` and `ios/` so the two stores stay consistent.
