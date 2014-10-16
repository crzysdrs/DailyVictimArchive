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

You may first need to run ```sudo make depends``` in Ubuntu 
to get all the dependencies installed. Afterwords, just run make.

```
make
```

To install, edit the variables ```HOST```, ```STAGE```, ```LIVE```
and run the corresponding ```make stage``` or ```make live```
to put the site on your webserver.

## Misc

Git-Annex will get the archive from https://dl.dropboxusercontent.com/u/13119212/gamespy.tar.gz

The site based on these scripts is located at http://crzysdrs.sytes.net/dv/ .
