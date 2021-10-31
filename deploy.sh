#!/bin/bash
set -eoux pipefail
IFS=$'\n\t'
./build deploy
pngcrush -ow deploy/img/sprites.png
pngcrush -ow deploy/img/reunion.png
find deploy \( -iname "*.html" -o -iname "*.svg" \) -exec perl -pi -e 's@(href|src)="/(?!/)@\1="/dv/@ig' {} \;
rsync --chmod=u+rwx,g+rwx,o+rx -r deploy/ blockade:/var/www/html/dv
