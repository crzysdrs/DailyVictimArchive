# Daily Victim Archive

This repo contains all the build scripts neccesary to build the Daily Victim Archive along with the corresponding site.

This includes:
* Markdown Formatted Articles and Meta Articles
* All Daily Victim Images
* Alpha Masks of Specific Images
* Transparency Fill Data
* Google Map Generation Scripts
  * Graph of all connections
  * Group photo reunion
* Site
  * Jekyll Templates
  * Javascript/CSS

## Build

If you are on Ubuntu 15.04, these steps should fully build the entirety of
the Daily Victim Archive.

```
# Requires SuperUser permissions to install dependencies
sudo ./_depends
stack setup
# Invoke Git Annex to Retrieve Binary Files (images)
./build extract
# The production gets around an issue with Jekyll incorrectly copying symlinks
JEKYLL_ENV=production ./build -j
```

Optionally you can ```./build -j serve``` to view the in development
site locally in a web browser.

## Misc

Git-Annex will get the archive from https://dl.dropboxusercontent.com/u/13119212/gamespy.tar.gz

The site based on these scripts is located at http://crzysdrs.sytes.net/dv/ .
