#!/usr/bin/runhaskell
{-# LANGUAGE PackageImports #-}
import Development.Shake
import Development.Shake.Command
import Development.Shake.FilePath
import Development.Shake.Util
import System.Directory
import System.FilePath.Posix
import System.SetEnv
import "Glob" System.FilePath.Glob
import qualified Data.Map as Map
import System.Process
import Control.Monad

builddir =  "_build"
scriptdir = "_scripts"
localdir = "_local"
outdir = builddir </> "out"
tmpdir = builddir </> "tmp" 
dagdir = outdir </> "dags"
dbfile = outdir </> "dv.db"
mirrordir = builddir </> "archive" </> "mirror"
archivedir = builddir </> "archive"
localarticlemd id = "_local" </> "article" </> concat [id, ".md"]
finalarticlemd id = outdir </> "article" </> concat [id, ".md"]
alphaout id = tmpdir </> "alpha" </> concat [id, ".alpha.png"]
alphashape id = tmpdir </> "alpha" </> concat [id, ".alpha_shape"]
scorechart id = outdir </> "chart" </> concat [id, ".score.png"]
historychart id = outdir </> "chart" </> concat [id, ".history.png"]

dagfile id = outdir </> "dags" </> concat[id, ".png"]

article_ids = [x | x <- [10..700], x /= 12, x /= 18, x /= 228, x /= 464]
all_dags = map (dagfile . show) article_ids ++ [dagfile "all"]
all_md = map (finalarticlemd . show) article_ids
all_local_md = map (localarticlemd . show) article_ids
all_alpha = map alphaout ((map show article_ids) ++ ["fargo", "hotsoup", "gabe"])
all_shapes = map (alphashape . show) article_ids
all_charts = map (scorechart . show) article_ids ++ map (historychart . show) article_ids

dagfiles id = [dagdir </> concat [id,  x] | x <- [".png", ".plain", ".map"]]

feather_size = 2
main :: IO ()
main = do
  setEnv "PERL5LIB" scriptdir
  shakeArgs shakeOptions{shakeFiles=builddir} $ do
  
  want["all"]

  phony "extract" $ do
    () <- cmd ["git", "annex", "init"]
    Exit _ <- cmd ["git", "remote", "add", "web", "http://crzysdrs.sytes.net/dv.git"]
    cmd ["git", "annex", "get", "."]
    
  cachedir <- newCache $ \globpath-> do
    putNormal (concat ["Reading cached dir: ", globpath])
    files <- liftIO (glob globpath)
    return files

  phony "clean" $ do
    putNormal "Cleaning files in _build"
    removeFilesAfter builddir ["//*"]

  dbfile %> \db -> do
    need (all_local_md ++ [scriptdir </> "loaddb.py"])
    liftIO $ removeFiles "" [dbfile]
    cmd ["." </> scriptdir </> "loaddb.py", "_local" </> "article", dbfile]

  outdir </> "tiles" </> "*" %> \t -> do
    let id = takeFileName t
    let tiles = "." </> scriptdir </> "create_tiles.pl"
    putNormal id
    let dfile = case id of
                   "all" -> outdir </> "dags" </> "all.png"
                   "reunion" -> outdir </> "reunion.png"
                   _ -> error "Unknown tiled image"
    need [dfile]
    when (id == "all") $ need [outdir </> "dags" </> "all_poly.js"]
    cmd [tiles, "-v", "--path", dropFileName t, dfile]

  dagfiles "*" &%> \[dpng, dmap, dplain] -> do
    let id = takeFileName $ dropExtension $ dpng
    let dag = "." </> scriptdir </> "dag.pl"
    need [dag,  dbfile]
    cmd [dag, id, dagdir, dbfile]

  outdir </> "dags" </> "all_poly.js" %> \file -> do
    let polyfiles = dagfiles "all"
    let poly = "." </> scriptdir </> "poly.pl"
    need ([poly, dbfile] ++ polyfiles)
    cmd ([poly, dbfile] ++ polyfiles ++ [file])

  [tmpdir </> "alpha" </> "*.alpha.png", tmpdir </> "alpha" </> "*.mask.png"] &%> \[alpha, mask] -> do
    let alpha_cmd = "." </> scriptdir </> "alpha.py"
    let alpha_done_cmd = "." </> scriptdir </> "alpha_done.py"
    need [alpha_cmd, alpha_done_cmd]
    let id = (takeFileName . takeBaseName . takeBaseName) alpha
    let alphadone = localdir </> "alpha_done" </> concat [id,  ".mask.png"]
    let pre_alpha = localdir </> "alpha_data" </> concat [id, ".alpha"]
    let img_path = "img" </> "victimpics" </> concat [id, ".gif"]
    alpha_done_exist <- Development.Shake.doesFileExist alphadone
    Development.Shake.doesFileExist pre_alpha
    img_exist <- Development.Shake.doesFileExist img_path
    () <- if alpha_done_exist
      then do
        need [localarticlemd id]
        () <- cmd ["cp", alphadone, mask]
        cmd [alpha_done_cmd, alpha, localarticlemd id, mask]
      else do
        unless img_exist $ need [localarticlemd id]
        -- Dump the article image with opacity added
        () <- cmd $ [alpha_cmd, alpha, localarticlemd id, pre_alpha, "--if_exists", img_path]
        -- Dump just the opacity mask
        () <- cmd ["convert", alpha, "-alpha", "extract", mask]
        -- Feather the mask to clean up the edges
        cmd ["feather", "-d", show feather_size, mask, mask]

    -- Apply the mask to the final image
    cmd ["convert",  alpha, mask, "-alpha", "Off", "-compose", "CopyOpacity", "-composite", alpha]

  finalarticlemd "*" %> \file -> do
    let id = (takeFileName . takeBaseName) file
    need [localarticlemd id, dbfile, scriptdir </> "updatefm.py"]
    cmd [scriptdir </> "updatefm.py", localarticlemd id, dbfile, finalarticlemd id]
    
  scriptdir </> "alpha_shape" %> \file -> do
    let c = scriptdir </> "alpha_shape.c"
    need [c]
    Stdout magick <- cmd ["Magick++-config", "--cppflags", "--cxxflags", "--ldflags", "--libs"]
    cmd (["g++", c, "-o", file, "-lCGAL", "-lgmp", "-frounding-math", "-g"] ++ (words magick))

  [outdir </> "reunion.png", outdir </> "reunion.json"] &%> \[png, json] -> do
    let comp = "." </> scriptdir </> "composite.pl"
    need $ [comp] ++ all_alpha ++ all_shapes
    cmd [comp, dbfile, tmpdir, outdir]

  [scorechart "*", historychart "*"] &%> \[score, history] -> do
    let id = (takeFileName . takeBaseName . takeBaseName) score
    let plot = "." </> scriptdir </> "plot.py"
    need [plot, localarticlemd id]
    cmd [plot, localarticlemd id, scorechart id, historychart id]

  alphashape "*" %> \file -> do
    let id = (takeFileName . takeBaseName) file
    let alphashape_cmd = "." </> scriptdir </> "alpha_shape"
    let src = tmpdir </> "alpha" </> concat [id, ".mask.png"]
    need [src, alphashape_cmd]
    () <- cmd [alphashape_cmd, file, src]
    cmd ["touch", file]

  outdir </> "_redirect.htaccess" %> \r -> do
    let redir = "." </> scriptdir </> "redirects.py"
    all_meta <- getDirectoryFiles "_meta" ["//*.md"]
    need ([redir, "_config.yml"] ++ all_md ++ map (\x -> "_meta" </> x) all_meta)
    cmd [redir, "_meta", "_article", r]
         
  phony "prereq" $ do
    need ([dbfile,
           outdir </> "tiles" </> "reunion",
           outdir </> "tiles" </> "all",
           outdir </> "_redirect.htaccess"
          ] ++ all_dags ++ all_charts ++ all_md)

  phony "jekyll_build" $ do
    need ["prereq"]
    cmd ["jekyll", "build"]

  phony "all" $ do
    need ["jekyll_build"]

  phony "serve" $ do
    need ["prereq"]
    cmd ["jekyll", "serve", "--watch"]

  phony "dev" $ do
    need ["prereq"]
    cmd ["jekyll", "serve", "--watch", "--config", "_config.yml,_config.dev.yml"]
