#!/bin/bash
# Renders the real QML against a mock backend at many window sizes and states.
# Output: tests/ui/out/<scenario>_<page>_<W>x<H>.png (view them, or build a contact sheet
# with contact_sheet.py). Needs Qt6 Quick + QuickControls2 dev packages and g++.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
LINUX="$HERE/../.."
WORK="$HERE/out"; STAGE="$WORK/qml"
rm -rf "$WORK"; mkdir -p "$STAGE"
cp "$LINUX"/*.qml "$HERE/Mock.qml" "$STAGE/"
sed -i "s#qrc:/icons/assets/#file://$(cd "$LINUX" && pwd)/assets/#g" "$STAGE"/*.qml
g++ -std=c++17 -fPIC "$HERE/harness.cpp" $(pkg-config --cflags --libs Qt6Quick Qt6QuickControls2 Qt6Qml Qt6Gui Qt6Core) -o "$WORK/harness"
SIZES=${SIZES:-"300x300 320x480 360x640 400x560 440x560 460x640 520x900 380x1000 640x480 800x600 1024x768 1280x800 1920x1080 900x400"}
for sz in $SIZES; do
  w=${sz%x*}; h=${sz#*x}
  for sc in pro3 adaptive long_name left_only case_only all_low max disconnected; do
    QT_QPA_PLATFORM=offscreen "$WORK/harness" "$STAGE" $w $h $sc main "$WORK/${sc}_main_${sz}.png" nomin 2>/dev/null
  done
  for sc in pro3 disconnected; do
    QT_QPA_PLATFORM=offscreen "$WORK/harness" "$STAGE" $w $h $sc settings "$WORK/${sc}_settings_${sz}.png" nomin 2>/dev/null
  done
done
echo "Screenshots in $WORK"
