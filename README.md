# titan-layout

a symbol layer for the unihertz titan 2's physical keyboard, shipped as data instead of
as a process.

the titan's printed alt layer covers 16 of the 32 ascii symbols. the other 16 —
`~ = { } | \ ; $ % ^ ` & [ ] < >` — plus vi arrows, escape and tab live here, on
`ctrl+letter` and `fn+letter`.

no root, no accessibility service, no input method, nothing running in the background.

## why data, not a remapper

a remapper built on an accessibility service has to **consume every keypress and re-emit
it**. that is not a bug in any particular app, it is the only thing the api allows, and
it is why the titan's keyboard kept dying under one: the re-emit runs back through the
remapper's own input method, so if the ime binding, the accessibility binding, or its
helper process hiccups — a reboot is enough — letters silently vanish or storm. one
measured tap produced 110,224 injected key events.

this ships a **keychar map overlay** instead: a data file the input system reads once,
when it loads the keyboard. no service, no process, no injection, nothing to keep alive.
it is the same mechanism the titan's own printed alt layer uses. it cannot break at
runtime, because there is nothing running to break.

## layout

| key | ctrl / fn | key | ctrl / fn |
| --- | --- | --- | --- |
| w e t y | `~ = { }` | h j k l | ← ↓ ↑ → |
| i o p | `\| \ ;` | q | esc |
| s d f g | `$ % ^ \`` | a | tab |
| x c v | `& [ ]` | m r u | home, recents, notifications |
| b n | `< >` | z | sleep |

back is deliberately unbound — the system's back gesture already covers it.

`alt+space` is remapped to a plain space, which kills the oem symbol-picker popup.

### shift tier

every letter is spoken for above, so the editing keys the titan otherwise cannot send at
all live one tier up, on **shift + the layer**. each one is the vim command that means the
same thing, so there is nothing extra to memorise.

| shift + layer | sends | vim |
| --- | --- | --- |
| f | line home | `^` |
| s | line end | `$` |
| u | page up | `ctrl-u` |
| d | page down | `ctrl-d` |
| x | forward delete | `x` |
| y | copy | `y` |
| p | paste | `p` |

`hjkl` and `a` are deliberately absent from that table, because they are already taken and
they were free: a `ctrl`/`sym` row clears only its own modifier, so shift is still set when
the arrow is dispatched. **shift+layer+hjkl already selects by character** and
**shift+layer+a is already back-tab**. binding anything there would take that away.

two layouts ship in the one apk:

- **titan layer (ctrl + fn)** — both modifiers. ctrl is the fast one-finger chord.
- **titan layer (fn only)** — for shells and anything else that owns ctrl (`ctrl+c` is
  SIGINT). fn emits `KEYCODE_SYM`, which nothing claims, so it survives where ctrl does
  not.

pick either in setup step 2; both are always installed, so switching is a menu tap, not
a rebuild.

## install

download the apk from
[the latest release](https://github.com/mellen9999/titan-layout/releases/latest) and open
it on the phone (or `adb install` it), then do the four setup steps below.

every release is signed with the same key, so upgrades install in place, and
[obtainium](https://github.com/ImranR98/Obtainium) can track this repo for updates.

the released apk embeds the titan 2's key table. on any other phone, [build it
yourself](#build) — the generator is not titan-specific.

## setup on the phone

each step lists the menu path and, where one exists, the setting it actually writes. the
menus belong to the oem and may move between builds; the settings keys are the durable
form, and `adb shell settings get <namespace> <key>` will tell you the current value.

1. **physical keyboard settings › KCM provider → Other**
   (`settings put global agui_kcm_provider 1`)
   the oem hides app-supplied keychar maps behind this. left at "Default", the layouts
   are not listed at all — this is the step people miss.
2. **same screen › TitanKey › layout → titan layer (ctrl + fn)**
   the only step with no adb equivalent: the choice lives in
   `/data/system/input-manager-state.xml`, which is root-only. it survives reboots, and
   is lost only if the apk is fully uninstalled.
3. **shortcut-key settings › Fn key › programmable key → Sym key**
   (`settings put system fn_programmable_key_function 2`)
   makes fn emit `KEYCODE_SYM`, a modifier no app or terminal claims.
4. **disable any accessibility-based key remapper.** with a service still eating keys,
   none of the above matters.

if a menu is not where this says, search the settings app for "physical keyboard" — the
overlay is a stock android feature and every build exposes it somewhere.

## when it does not work

| symptom | cause |
| --- | --- |
| the layout is not in the picker at all | KCM provider is still "Default" (step 1) |
| installed and selected, nothing changed | the layout choice was dropped — reselect it (step 2) |
| ctrl chords work, fn does nothing | fn is not set to Sym (step 3) |
| keys vanish or storm at random | an accessibility remapper is still enabled (step 4) |
| ctrl chords swallowed inside a terminal | expected — the shell owns ctrl; use fn, or the fn-only layout |

`adb logcat | grep AguiKeyboardShortcut` logs every dispatched keycode, which is the
fastest way to see what a key actually sends.

## build

needs python 3, a jdk, android build-tools (aapt2, zipalign, apksigner) and adb. no
android platform sdk: the build pulls `framework-res.apk` off the phone and uses that as
the aapt2 include.

```sh
./build.sh                                  # pulls what it needs, generates, signs
adb install -r build/titan-layout.apk
```

on first run it pulls the phone's stock keychar map and generates a signing key beside
the script; keep both if you want upgrades to install in place.

`gen.py` derives every layout from whatever stock map it is given, so it is not
titan-specific — point it at another phone's keychar map and it builds that phone's
layer. edit `SYMBOLS` and `NAV` to change the bindings.

## notes found the hard way

- an overlay **replaces a key wholesale**, so every touched key must be restated in full,
  including its base and alt rows.
- the stock map already declares `shift+alt` on every letter. declaring it again is a
  "Duplicate modifier combination" and the whole file fails to parse — drop the stock row
  first rather than appending to it.
- `sym` and `replace <KEYCODE>` are both accepted by the keychar map parser
  (`strings libinput.so` if you want to confirm it on your own build).
- the titan 2 has **no ctrl scancode**. the key next to shift reports
  `KEYCODE_CTRL_LEFT` only because the oem layer synthesizes it.
- `getevent` output is lost if you pipe it through grep and then kill it — buffering.
  write to a file on the phone instead.

built and verified on a unihertz titan 2 running android 16, august 2026.

## license

0BSD. do whatever.
