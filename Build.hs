#!/usr/bin/runhaskell

import Development.Shake
import Development.Shake.Command
import Development.Shake.FilePath
import Development.Shake.Util
import System.Directory
import System.FilePath.Posix
import System.SetEnv
import System.FilePath.Glob
import qualified Data.Map as Map
import System.Process

sortAndGroup assocs = Map.fromListWith (++) [(k, [v]) | (k, v) <- assocs]

votefile id = concat ["_build/archive/archive.gamespy.com/comics/DailyVictim/vote.asp_id_", id, "_dontvote_true"]
htmlfile id = concat ["_build/archive/archive.gamespy.com/Dailyvictim/index.asp_id_", id, ".html"]
articlefile id = concat [tmpdir, "/", id, ".article"]
mirrorhtml id = concat ["_build/archive/mirror/", id, ".html"]
mirrorvote id = concat ["_build/archive/mirror/", id, ".vote.html"]
historyfile id = concat ["_build/archive/history/", id, ".*.html"]
alphaout id = concat ["_build/tmp/alpha/", id, ".alpha.png"]
alphashape id = concat ["_build/tmp/alpha/", id, ".alpha_shape"]
scorechart id = concat [outdir, "/chart/", id, ".score.png"]
historychart id = concat [outdir, "/chart/", id, ".history.png"]

dagfile id = concat [outdir, "/dags/", id, ".png"]
voteout id = concat [tmpdir, "/", id, ".vote"]
         
article_ids = [x | x <- [10..700], x /= 12, x /= 18, x /= 228, x /= 464]
all_articles = map (articlefile . show) article_ids
all_dags = map (dagfile . show) article_ids ++ [dagfile "all"]
all_votes = map (voteout . show) article_ids
all_alpha = map alphaout ((map show article_ids) ++ ["fargo", "hotsoup", "gabe"])
all_shapes = map (alphashape . show) article_ids
all_charts = map (scorechart . show) article_ids ++ map (historychart . show) article_ids

anatomy_html =  [mirrordir ++ "/anatofvictim." ++ show x ++ ".html" | x <- [1..5]]
top10_html =  [mirrordir ++ "/top10." ++ show x ++ ".html" | x <- [1..4]]
dagfiles id = [dagdir ++ "/" ++ id ++ x | x <- [".png", ".plain", ".map"]]

builddir = "_build"
outdir = concat [builddir, "/out"]
tmpdir = concat [builddir, "/tmp"]
dagdir = concat [outdir, "/dags"]
dbfile = concat [outdir, "/dv.db"]
mirrordir = "_build/archive/mirror"
archivedir = "_build/archive"

feather_size = 2
main :: IO ()
main =
  shakeArgs shakeOptions{shakeFiles="_build"} $ do
  want["all"]

  phony "extract" $ do
    () <- cmd ["git", "annex", "init"]
    () <- cmd ["git", "annex", "get", "."]
    need ["gamespy.tar.gz"]
    () <- cmd ["mkdir", "-p", archivedir]
    cmd ["tar", "xf", "gamespy.tar.gz", "-C", archivedir]         
    
  phony "depends" $ do
    -- Ubuntu dependency installation
    () <- cmd ["cpan", "install", "Lingua:EN:Titlecase:HTML"]
    cmd ["apt-get", "install",
         "gnuplot",
         "graphviz",
         "libimage-size-perl",
         "imagemagick",
         "libdbd-sqlite3-perl",
         "sqlite3",
         "tidy",
         "libgraphicsmagick1-dev",
         "graphicsmagick-libmagick-dev-compat",
         "libcode-tidyall-perl",
         "php-codesniffer",
         "libmagickcore-6-arch-config",
         "libfile-slurp-unicode-perl",
         "libencode-perl",
         "libcgal-dev",
         "libmoosex-getopt-perl",
         "git-annex",
         "libjson-perl"
        ]
      
  cachedir <- newCache $ \globpath-> do
    putNormal (concat ["Reading cached dir: ", globpath])
    files <- liftIO (glob globpath)
    return files

  history_map <- newCache $ \globpath -> do
    files <- cachedir globpath
    let keyed_list =  zip (map (takeFileName . takeBaseName .takeBaseName .takeBaseName . takeBaseName) files) files
    let fixed_map = Map.fromListWith (++) . map (\(x,y) -> (x,[y])) $ keyed_list
    return fixed_map
    
  phony "clean" $ do
    putNormal "Cleaning files in _build"
    removeFilesAfter "_build" ["//*"]

  voteout "*" %> \v -> do
    let id = takeFileName $ dropExtension $ v
    let votefiles = if (read id) <= 696
                    then [votefile id, mirrorvote id]
                    else []
    need votefiles
    all_history <- history_map "_build/archive/history/*.html"
    let history_ids = Map.lookup id all_history
    case history_ids of
      Just h -> need h
      Nothing -> return ()
    let all_votefiles = case history_ids of
          Just h -> votefiles ++ h
          Nothing -> votefiles          
    cmd (["./vote.pl", v, id] ++ all_votefiles)
     
  dbfile %> \db -> do
    need (anatomy_html ++ top10_html ++ all_articles ++ all_votes ++ ["loaddb.pl"])
    liftIO $ removeFiles "" [dbfile]
    cmd ["./loaddb.pl", dbfile, tmpdir, mirrordir]
                
  articlefile "*" %> \out -> do
    let id = takeFileName $ dropExtension $ out
    let (html, vote) = if (read id) <= 696
                       then (htmlfile id, Just (votefile id))
                       else if (read id) == 700
                       then (mirrorhtml id, Just (mirrorvote id))
                       else (mirrorhtml id, Nothing)
    let vote_str = case vote of
          Just x -> x
          Nothing -> "NO VOTE DATA"     
    need ["article.pl", html]    
    case vote of
      Just v -> need[v]
      Nothing -> return ()
  
    cmd ["./article.pl", articlefile id, id, html, vote_str]

  "_build/out/tiles/*" %> \t -> do
    let id = takeFileName t
    putNormal id
    let dfile = case id of
                   "all" -> "_build/out/dags/all.png"
                   "reunion" -> "_build/out/reunion.png"
                   _ -> error "Unknown tiled image"
    need [dfile]
    () <- if id == "all"
      then need ["_build/out/dags/all_poly.js"]
      else return ()
    cmd ["./create_tiles.pl", "-v", "--path", dropFileName t, dfile]

  dagfiles "*" &%> \[dpng, dmap, dplain] -> do
    let id = takeFileName $ dropExtension $ dpng
    need ["./dag.pl", dbfile]
    cmd ["./dag.pl", id, dagdir, dbfile]

  "_build/out/dags/all_poly.js" %> \file -> do
    let polyfiles = dagfiles "all"
    need (["poly.pl", dbfile] ++ polyfiles)
    cmd (["./poly.pl", dbfile] ++ polyfiles ++ [file])

  [concat [tmpdir, "/alpha/*.alpha.png"], concat [tmpdir, "/alpha/*.mask.png"]] &%> \[alpha, mask] -> do
    need ["alpha.pl", "alpha_done.pl"]
    let id = (takeFileName . takeBaseName . takeBaseName) alpha
    let alphadone = concat ["alpha_done/", id, ".mask.png"]
    let pre_alpha = concat ["alpha_data/", id, ".alpha"]
    let img_path = concat ["_build/archive/img/victimpics/", id, ".gif"]
    alpha_done_exist  <- Development.Shake.doesFileExist alphadone
    alphadata_exist <- Development.Shake.doesFileExist pre_alpha
    img_exist <- Development.Shake.doesFileExist img_path
    () <- if alpha_done_exist
      then do
        need [articlefile id]
        () <- cmd ["cp", alphadone, mask]
        cmd ["./alpha_done.pl", alpha, id, articlefile id, mask]
      else do
        let alpha_args = if alphadata_exist
                           then ["-alpha", pre_alpha]
                           else []
        let file_args = if img_exist
                           then ["-file", img_path]
                           else ["-article", articlefile id]
        () <- if img_exist
                then return ()
                else need [articlefile id]
        -- Dump the article image with opacity added
        () <- cmd $ ["./alpha.pl", "-target", alpha] ++ alpha_args ++ file_args
        -- Dump just the opacity mask
        () <- cmd ["convert", alpha, "-alpha", "extract", mask]
        -- Feather the mask to clean up the edges
        cmd ["feather", "-d", show feather_size, mask, mask]

    -- Apply the mask to the final image
    cmd ["convert",  alpha, mask, "-alpha", "Off", "-compose", "CopyOpacity", "-composite", alpha]
    
  "alpha_shape" %> \file -> do
    need ["alpha_shape.c"]
    Stdout magick <- cmd ["Magick++-config", "--cppflags", "--cxxflags", "--ldflags", "--libs"]
    cmd (["g++", "alpha_shape.c", "-o", file, "-lCGAL", "-lgmp", "-frounding-math", "-g"] ++ (words magick))

  ["_build/out/reunion.png", "_build/out/reunion.json"] &%> \[png, json] -> do
    need $ ["./composite.pl"] ++ all_alpha ++ all_shapes
    cmd ["./composite.pl", dbfile, tmpdir, outdir]

  [scorechart "*", historychart "*"] &%> \[score, history] -> do
    let id = (takeFileName . takeBaseName . takeBaseName) score
    need ["plot.pl", voteout id]
    cmd ["./plot.pl", score, history, id, voteout id]
  
  alphashape "*" %> \file -> do
    let id = (takeFileName . takeBaseName) file
    let src = concat [tmpdir, "/alpha/", id, ".mask.png"]
    need [src, "./alpha_shape"]
    () <- cmd ["./alpha_shape", file, src]
    cmd ["touch", file]
    
  phony "all" $ do
    need ([dbfile, "_build/out/tiles/reunion", "_build/out/tiles/all"] ++ all_dags ++ all_charts)
