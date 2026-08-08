#!/usr/bin/env bash
# build + sign the layout apk. framework-res.apk is pulled from the phone and used
# as the aapt2 include, so no android platform sdk is needed.
set -euo pipefail
cd "$(dirname "$0")"

# find build-tools wherever this distro puts them; fall back to whatever is on PATH
for d in "${ANDROID_HOME:-}/build-tools" "${ANDROID_SDK_ROOT:-}/build-tools" \
         /opt/android-sdk/build-tools "$HOME/Android/Sdk/build-tools"; do
  [ -d "$d" ] || continue
  BT=$(ls -d "$d"/* 2>/dev/null | sort -V | tail -1)
  [ -x "$BT/aapt2" ] && break
  BT=
done
if [ -z "${BT:-}" ]; then
  command -v aapt2 >/dev/null || { echo "need android build-tools (aapt2, zipalign, apksigner)" >&2; exit 1; }
  BT=$(dirname "$(command -v aapt2)")
fi

mkdir -p build
# the phone's own framework resources stand in for the platform sdk's android.jar
[ -f build/framework-res.apk ] || adb pull /system/framework/framework-res.apk build/framework-res.apk
# the stock keychar map is what gen.py overlays; pull it if this is someone else's phone
[ -f TitanKey.orig.kcm ] || adb pull /system/usr/keychars/TitanKey.kcm TitanKey.orig.kcm

umask 077
[ -f key.pass ] || head -c 24 /dev/urandom | base64 > key.pass
PW=$(cat key.pass)
[ -f titan.keystore ] || keytool -genkeypair -keystore titan.keystore -alias titan \
  -keyalg RSA -keysize 2048 -validity 10950 -storepass "$PW" -keypass "$PW" \
  -dname "CN=titan-layout, O=titan-layout"

python3 gen.py
"$BT/aapt2" compile --dir res -o build/res.zip
"$BT/aapt2" link -o build/unsigned.apk --manifest AndroidManifest.xml \
  -I build/framework-res.apk build/res.zip
"$BT/zipalign" -f 4 build/unsigned.apk build/aligned.apk
"$BT/apksigner" sign --ks titan.keystore --ks-key-alias titan \
  --ks-pass "pass:$PW" --key-pass "pass:$PW" --out build/titan-layout.apk build/aligned.apk
echo "built build/titan-layout.apk"
