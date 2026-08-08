#!/usr/bin/env bash
# build + sign the layout apk. framework-res.apk is pulled from the phone and used
# as the aapt2 include, so no android platform sdk is needed.
set -euo pipefail
cd "$(dirname "$0")"

BT=$(ls -d /opt/android-sdk/build-tools/* | tail -1)
mkdir -p build
[ -f build/framework-res.apk ] || adb pull /system/framework/framework-res.apk build/framework-res.apk

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
