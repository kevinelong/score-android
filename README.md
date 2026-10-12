# Score — two-team scoreboard for Android

A single-screen score keeper for two teams. **HOME on the left, AWAY on the right** — tap the big
number to add a point, flick up or down to move the score, hold a team name to rename it.

![portrait](screenshots/portrait.png)

## Download

**[⬇︎ Download `score-release.apk`](https://github.com/kevinelong/score-android/releases/latest)**

| | |
| --- | --- |
| Version | 1.1 (versionCode 2) |
| Size | 79,239 bytes |
| SHA-256 | `3d218767d0ded3904fdb659b57ccb1f290e34a52c7a6cc157898559df94a8aae` |
| Requires | Android 5.0 (API 21) or newer |
| Permissions | `INTERNET`, used only when you open a scoring link |
| Package | `com.kevin.score` |

Check the download before installing it — on Windows
`certutil -hashfile score-release.apk SHA256`, on macOS/Linux `shasum -a 256 score-release.apk`. The
build is reproducible, so that hash identifies the release exactly. The same file is committed to this
repository for a direct link:
[`score-release.apk`](https://github.com/kevinelong/score-android/raw/main/score-release.apk).

## Install

Android only offers installs from the Play Store by default, so the first sideload needs one
permission and, on a Samsung, one security toggle:

1. Download the APK on the phone.
2. **Samsung: turn Auto Blocker off first.** Settings → **Security and privacy** → **Auto Blocker** →
   off. It is on by default on newer Galaxies and it refuses installs from outside the Play Store
   outright. Turn it back on afterwards; the installed app keeps working.
3. Open the file from **My Files** (or **Files**) → Downloads. The first attempt asks whether to allow
   installing from that app — tap **Settings** in the prompt and enable **Allow from this source**.
4. Google Play Protect warns that the app is not from the Play Store. That is expected for any
   sideloaded app — choose **Install anyway**.
5. Open **Score** from the app drawer.

With a computer and Android platform-tools instead:
`adb install -r score-release.apk` (needs USB debugging enabled and Auto Blocker off).

## How to use

- **Add a point:** tap the big number, or the green **+**.
- **Take a point off:** tap the red **−**.
- **Swipe up or down anywhere on either side** to move that side by one — up adds, down subtracts.
- **Reset a side:** the **Reset** button under its buttons.
- **Rename a team:** press and hold the name for about a second. It dims while you hold, then the
  rename dialog opens; let go early and nothing happens. Names are limited to 16 characters, and
  clearing the name restores `HOME` / `AWAY`.
- Scores run `00`–`99` per side. Names and scores survive rotating the phone, and the screen is kept
  awake while the app is open — a scoreboard that sleeps mid-match is useless.

![landscape](screenshots/landscape.png)

## Linked match mode

If a tournament director shares a **scoring link** with you, opening it on your phone loads that match
into the app: the two entrants appear as HOME and AWAY, you tally the points, and **Submit result**
records the winner on the tournament server (the tallies go with it). **Correct result** reopens a
match you already recorded, so a mistake can be fixed — the server keeps both versions.

Without the app installed, the same link opens the tournament's web console in a browser instead, so
the link always works. The app contacts only the host named in that link, and only to read the match
and send its result.

![a match opened from a scoring link](screenshots/linked.png)

## Privacy

Nothing leaves the phone unless you open a tournament scoring link. Opened normally from the home
screen, the app uses no network at all. The `INTERNET` permission exists for **linked match mode**,
where the app talks to the host of the link you opened — to read that one match and to submit its
result (the winner, the two team names and your tallies). No other host is contacted, there is no
account, no ads, no analytics, no third-party libraries, and nothing is collected, so there is nothing
to opt out of.

## Notes

- The app is signed with a 4096-bit RSA release key; signature schemes v1, v2 and v3 are all present,
  so it installs on every Android from 5.0 up.
- If you have an older copy installed, this release updates it in place — as long as it was signed
  with the same key, which it was.
- **Source:** the source lives in a separate, public repository —
  [kevinelong/score](https://github.com/kevinelong/score) — with the build scripts, the tools and the
  verification harness.
- **Licence:** **`FSL-1.1-MIT`** — the [Functional Source
  License](https://fsl.software/) ([full text](LICENSE)). In short: use, copy, modify and redistribute
  the app freely, **including commercially**, for anything except a competing product — you may not
  ship it as, or inside, a scoreboard that substitutes for this one. Two years after each release it
  becomes plain MIT. This makes it source-available rather than open source; if you need different
  terms, ask.
