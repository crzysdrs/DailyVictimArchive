# Daily Victim Archive

This repo contains all the build scripts neccesary to build the Daily Victim Archive along with the corresponding site.

This includes:
* Archive Munging Scripts
* Alpha Masks of Specific Images
* Transparency Fill Data
* Google Map Generation Scripts
  * Graph of all connections
  * Group photo reunion
* Site
  * Smarty Templates
  * Javascript/CSS
  * PHP files

## Build

If you are on Ubuntu 15.04, these steps should fully build the entirety of
the Daily Victim Archive.

```
# Requires SuperUser permissions to install dependencies
sudo ./depends
# Extracting some file s
./build extract
./build -j
```

## Misc

Git-Annex will get the archive from https://dl.dropboxusercontent.com/u/13119212/gamespy.tar.gz

The site based on these scripts is located at http://crzysdrs.sytes.net/dv/ .
