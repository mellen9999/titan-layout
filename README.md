# titan-layout

a symbol layer for the unihertz titan 2's physical keyboard that has no moving parts.

the titan's printed alt layer covers 16 of the 32 ascii symbols. the other 16 —
`~ = { } | \ ; $ % ^ ` & [ ] < >` — plus arrow keys and escape live here, on
`ctrl+letter` and `fn+letter`.

## why not key mapper

key mapper (and anything else built on an accessibility service) has to **consume every
keypress and re-emit it**. that is the whole design, and it is why the titan's keyboard
kept dying: the re-emit runs through key mapper's own input method, so if the ime
binding, the accessibility binding, or its shell-uid `keymapper_sysbridge` hiccups — a
reboot is enough — letters silently vanish or storm. one measured tap produced 110,224
injected key events.

this ships a **keychar map overlay** instead: a data file the input system reads when it
loads the keyboard. no service, no process, no injection, nothing to keep alive. it is
the same mechanism the titan's own printed alt layer uses. it cannot break, because
there is nothing running to break.

## layout

| key | ctrl / fn | key | ctrl / fn |
| --- | --- | --- | --- |
| w e t y | `~ = { }` | h j k l | ← ↓ ↑ → |
| i o p | `\| \ ;` | q | esc |
| s d f g | `$ % ^ \`` | a | tab |
| x c v | `& [ ]` | m r u | home, recents, notifications |
| b n | `< >` | z | sleep |

`alt+space` is remapped to a plain space, which kills the oem symbol-picker popup.

two layouts are built: `ctrl + fn` and `fn only`. ctrl is the fast one-finger chord, but
terminals own ctrl (`ctrl+c` is SIGINT), so **fn is the route that works inside termux**.
fn has to be set to "Sym key" for that — see setup.

## install

grab the apk from [releases](../../releases) and `adb install` it (or open it on the
phone), then do the four setup steps below. obtainium can track this repo if you want
updates. every release is signed with the same key, so upgrades install in place.

if you are not on a titan 2, build it yourself — the apk embeds *this* phone's key table.

## build

needs `android-sdk-build-tools`, a jdk, and adb. no android platform sdk: the build pulls
`framework-res.apk` off the phone and uses it as the aapt2 include.

```sh
adb pull /system/usr/keychars/TitanKey.kcm TitanKey.orig.kcm   # your phone's stock map
./build.sh
adb install -r build/titan-layout.apk
```

`gen.py` derives every layout from the stock map, so it is not titan-2-specific — point
it at another phone's keychar map and it will build that phone's layer. edit `SYMBOLS`
and `NAV` to change the bindings.

## setup on the phone

1. **settings › system › languages & input › physical keyboard › KCM provider → Other**
   the oem hides app-supplied keychar maps behind this. at "Default" the layouts do not
   appear at all. (adb: `settings put global agui_kcm_provider 1`)
2. **same screen › TitanKey › layout → titan layer (ctrl + fn)**
   this is the only step with no adb equivalent — the choice lives in
   `/data/system/input-manager-state.xml`, which is root-only. it survives reboots and is
   only lost if the apk is fully uninstalled.
3. **settings › shortcut keys › Fn key › programmable key → Sym key**
   makes fn emit `KEYCODE_SYM`, a modifier nothing claims.
   (adb: `settings put system fn_programmable_key_function 2`)
4. disable key mapper if you were using it — with an accessibility service still eating
   keys, none of this matters. (`adb shell pm disable-user --user 0 io.github.sds100.keymapper`)

## notes found the hard way

- an overlay **replaces a key wholesale**, so every touched key must be restated in full,
  including its base and alt rows.
- the stock map already declares `shift+alt` on every letter. declaring it again is
  "Duplicate modifier combination" and the whole file fails to parse — drop the stock row
  first.
- `sym` and `replace <KEYCODE>` are both accepted by the parser in android 16
  (`strings libinput.so` if you want to check your build).
- the titan 2 has **no ctrl scancode**. the key next to shift emits `KEYCODE_CTRL_LEFT`
  because the oem layer synthesizes it.
- verify with `adb logcat | grep AguiKeyboardShortcut`, which logs every dispatched
  keycode. it is the fastest way to see what a key actually sends.

## license

0BSD. do whatever.
