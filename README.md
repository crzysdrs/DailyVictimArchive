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
  * Zola Templates
  * Javascript/CSS

## Build

Requires docker with BuildKit, but otherwise should be pretty easy.

```
sudo apt install docker-buildx git-annex
sudo usermod -aG docker $USER
# Invoke Git Annex to Retrieve Binary Files (images)
./build extract
# Build all intermediates
./build -j
```

Optionally you can ```./build -j serve``` to view the in development
site locally in a web browser.

## Misc

Git-Annex will get files found in [gamespy.tar.gz](https://crzysdrs.net/gamespy.tar.gz)

The site based on these scripts is located at http://crzysdrs.net/dv/ .
