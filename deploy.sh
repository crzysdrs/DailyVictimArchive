#!/bin/bash
set -eoux pipefail
IFS=$'\n\t'
zola build --output-dir deploy
find deploy -iname "*.html" -exec perl -pi -e 's@(href|src)="/(?!/)@\1="/dv/@ig' {} \;
rsync --chmod=u+rwx,g+rwx,o+rx -r deploy/ blockade:/var/www/html/dv
