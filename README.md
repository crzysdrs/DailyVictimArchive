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
# Extracting some archived files
./build extract
# Building the entire project
./build -j
```

## Misc

The site based on these scripts is located at http://crzysdrs.sytes.net/dv/ .
