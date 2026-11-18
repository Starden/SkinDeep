# SkinDeep

**Damage skins for the floating combat numbers in World of Warcraft: Forever.**

SkinDeep replaces the numbers that pop over your enemies with animated, themed
"damage skins": custom fonts, motion, colors, crit bursts and particles. It ships
with 19 skins, including one for every class and a slot-machine skin that rolls
every hit and hits the JACKPOT on crits.

Type `/skindeep` to open the skin picker with a live preview.

## Skins

**Auto: my class** (the default) uses your current character's class skin, so
every character gets its own look.

| Class skins | |
|---|---|
| **Bloodrage** (Warrior) | Numbers slam down from above; crits crack the ground and throw debris. |
| **Lightbringer** (Paladin) | Radiant numbers rise in state; crits call down a column of light. |
| **Dead Eye** (Hunter) | Numbers fly in like arrows; crits snap a crosshair onto the target. |
| **Cutthroat** (Rogue) | Slanted numbers blink in and vanish; crits slash an X and spill poison. |
| **Halo** (Priest) | Soft glowing numbers float under a halo; crits shed feathers. |
| **Stormcall** (Shaman) | Crystal numbers crackle upward; crits fork chain lightning. |
| **Spellweave** (Mage) | Sparks converge and the number bursts out; crits ripple fire, frost and arcane. |
| **Fel Pact** (Warlock) | Flickering numbers over a fel sigil; crits flare fel fire and a void ring. |
| **Wild Bloom** (Druid) | Numbers sway up like falling leaves; crits bloom a flower. |

| Style skins | |
|---|---|
| **Jackpot** | Every hit is a little slot roll; crits on your target open a cabinet that lands on your crit and pays out in coins. |
| **Classic+** | Blizzard's look, with a cleaner crit pop. |
| **Ember Tide** | Flickering fire numbers on a trail of embers. |
| **Frostbite** | Crystal numbers slam in and shed ice shards. |
| **Arcane Sigil** | Dotted runic digits spiral out of a turning sigil. |
| **Kaboom!** | Chunky 3D comic numbers that bounce, with POW bursts. |
| **Bloodmoon Ink** | Gothic numbers splash onto ink blots and drip away. |
| **Retro Arcade** | Pixel numbers hop up in steps; crits flash every color. |
| **Gilded Hoard** | Beveled gold numbers tossed like coins. |
| **Swiftblade** | Slanted steel numbers dash sideways with a motion trail. |

## Colors

Physical and spell damage always read apart, like Blizzard's white and yellow:

- **Skin palette**: each skin's own pair (physical paler, spell stronger).
- **Classic**: physical white, spell yellow on every skin.
- **Spell schools**: Fire orange, Frost blue, Shadow purple and so on.

## Options

`/skindeep` (or the addon compartment button) opens the settings window:

- **Numbers**: replace Blizzard's numbers, show both, or only restyle Blizzard's
  (their font and motion).
- Enemy nameplates (AoE), damage you take, heals you receive.
- Bursts and particles, skin sounds, abbreviated big numbers, size and speed.
- **Blizzard's numbers in groups**: off by default. See *Groups* below.

Slash commands: `/skindeep test`, `/skindeep list`, `/skindeep skin <name>`,
`/skindeep on`, `/skindeep off`, `/skindeep restore`, `/skindeep unlock`.

## Good to know

- **Groups:** the game doesn't tell addons whose hit landed on your target, so in
  a party SkinDeep also shows your party's hits on your target. Tick
  *Blizzard's numbers in groups* to hand back to Blizzard's numbers (which only
  show yours) while grouped.
- **Hidden amounts:** WoW: Forever hides damage amounts from addons in combat.
  Addons can show them but not read them, so effects like Jackpot's rolling reels
  spin random numbers before landing on the real hit.
- **Blizzard's font** changes at your next login (the game reads it once).
- **Uninstalling:** SkinDeep hands back every game setting it changes each time
  you log out. `/skindeep restore` does it on the spot.

## Development

The shipped addon is the Lua files, `SkinDeep.toc` and `Media/`. Everything else
is tooling (needs Node.js):

```bash
npm install
npm test          # Lua syntax check + mock-client test suite
npm run assets    # regenerate fonts, textures and the logo
```

- `tools/make_fonts.js` and `tools/make_textures.js` generate all fonts and
  textures from code, so every asset is original and MIT-licensed.
- `tests/` runs the addon in a Lua VM against a mocked WoW API, including
  secret (unreadable) combat values.
- `tools/install.ps1` copies the addon into your WoW: Forever AddOns folder.

Releases: pushing a tag like `v1.2.0` runs the tests, then the
[BigWigs packager](https://github.com/BigWigsMods/packager) builds the zip and
uploads it to CurseForge and GitHub (see `.github/workflows/release.yml`).

## License

MIT, see [LICENSE](LICENSE).
