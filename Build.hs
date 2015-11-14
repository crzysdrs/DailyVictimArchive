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
import Text.Pandoc

sortAndGroup assocs = Map.fromListWith (++) [(k, [v]) | (k, v) <- assocs]

builddir =  "_build"
scriptdir = "_scripts"
localdir = "_local"
outdir = builddir </> "out"
tmpdir = builddir </> "tmp" 
dagdir = outdir </> "dags"
dbfile = outdir </> "dv.db"
mirrordir = builddir </> "archive" </> "mirror"
archivedir = builddir </> "archive"
votefile id = builddir </> "archive" </> "archive.gamespy.com" </> "comics" </> "DailyVictim" </> concat ["vote.asp_id_", id, "_dontvote_true"]
htmlfile id = builddir </> "archive" </> "archive.gamespy.com" </> "Dailyvictim" </> concat ["index.asp_id_", id, ".html"]
articlefile id = tmpdir </> concat [id, ".article"]
articlemd id = tmpdir </> concat [id, ".md"]
mirrorhtml id = mirrordir </> concat [id, ".html"]
mirrorvote id = mirrordir </> concat [id, ".vote.html"]
historyfile id = concat [builddir, "/archive/history/", id, ".*.html"]
alphaout id = tmpdir </> "alpha" </> concat [id, ".alpha.png"]
alphashape id = tmpdir </> "alpha" </> concat [id, ".alpha_shape"]
scorechart id = outdir </> "chart" </> concat [id, ".score.png"]
historychart id = outdir </> "chart" </> concat [id, ".history.png"]

dagfile id = outdir </> "dags" </> concat[id, ".png"]
voteout id = tmpdir </> concat [id, ".vote"]

article_ids = [x | x <- [10..700], x /= 12, x /= 18, x /= 228, x /= 464]
all_articles = map (articlefile . show) article_ids
all_dags = map (dagfile . show) article_ids ++ [dagfile "all"]
all_md = map (articlemd . show) article_ids
all_votes = map (voteout . show) article_ids
all_alpha = map alphaout ((map show article_ids) ++ ["fargo", "hotsoup", "gabe"])
all_shapes = map (alphashape . show) article_ids
all_charts = map (scorechart . show) article_ids ++ map (historychart . show) article_ids

anatomy_html =  [mirrordir </> concat ["anatofvictim.", show x, ".html"] | x <- [1..5]]
top10_html =  [mirrordir </>  concat ["top10.", show x, ".html"] | x <- [1..4]]
dagfiles id = [dagdir </> concat [id,  x] | x <- [".png", ".plain", ".map"]]


feather_size = 2
main :: IO ()
main = do
  setEnv "PERL5LIB" scriptdir
  shakeArgs shakeOptions{shakeFiles=builddir} $ do
  
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
         "libwebp-dev",
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
    removeFilesAfter builddir ["//*"]

  voteout "*" %> \v -> do
    let id = takeFileName $ dropExtension $ v
    let votefiles = if (read id) <= 696
                    then [votefile id, mirrorvote id]
                    else []
    need votefiles
    all_history <- history_map (builddir </> "archive" </> "history" </> "*.html")
    let history_ids = Map.lookup id all_history
    case history_ids of
      Just h -> need h
      Nothing -> return ()
    let all_votefiles = case history_ids of
          Just h -> votefiles ++ h
          Nothing -> votefiles
    cmd (["." </> scriptdir </> "vote.pl", v, id] ++ all_votefiles)

  dbfile %> \db -> do
    need (anatomy_html ++ top10_html ++ all_articles ++ all_votes ++ [scriptdir </> "loaddb.pl"])
    liftIO $ removeFiles "" [dbfile]
    cmd ["." </> scriptdir </> "loaddb.pl", dbfile, tmpdir, mirrordir]

  articlemd "*" %> \out -> do
    let id = takeFileName $ dropExtension $ out
    let mdformatter = "." </> scriptdir </> "articlefm.py"
    need [mdformatter, articlefile id]
    --let getMeta (Pandoc m a) = m
    --stringify $ fromJust $ lookupMeta "title" (getMeta (fromRight doc))
    cmd [mdformatter, articlefile id, out]

  articlefile "*" %> \out -> do
    let id = takeFileName $ dropExtension $ out
    let article ="." </> scriptdir </> "article.pl"          
    let (html, vote) = if (read id) <= 696
                       then (htmlfile id, Just (votefile id))
                       else if (read id) == 700
                       then (mirrorhtml id, Just (mirrorvote id))
                       else (mirrorhtml id, Nothing)
    let vote_str = case vote of
          Just x -> x
          Nothing -> "NO VOTE DATA"
    need [article, html]
    case vote of
      Just v -> need[v]
      Nothing -> return ()

    cmd [article, articlefile id, id, html, vote_str]

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
    let alpha_cmd = "." </> scriptdir </> "alpha.pl"
    let alpha_done_cmd = "." </> scriptdir </> "alpha_done.pl"
    need [alpha_cmd, alpha_done_cmd]
    let id = (takeFileName . takeBaseName . takeBaseName) alpha
    let alphadone = localdir </> "alpha_done" </> concat [id,  ".mask.png"]
    let pre_alpha = localdir </> "alpha_data" </> concat [id, ".alpha"]
    let img_path = builddir </> "archive" </> "img" </> "victimpics" </> concat [id, ".gif"]
    alpha_done_exist  <- Development.Shake.doesFileExist alphadone
    alphadata_exist <- Development.Shake.doesFileExist pre_alpha
    img_exist <- Development.Shake.doesFileExist img_path
    () <- if alpha_done_exist
      then do
        need [articlefile id]
        () <- cmd ["cp", alphadone, mask]
        cmd [alpha_done_cmd, alpha, id, articlefile id, mask]
      else do
        let alpha_args = if alphadata_exist
                           then ["-alpha", pre_alpha]
                           else []
        let file_args = if img_exist
                           then ["-file", img_path]
                           else ["-article", articlefile id]
        unless img_exist $ need [articlefile id]
        -- Dump the article image with opacity added
        () <- cmd $ [alpha_cmd, "-target", alpha] ++ alpha_args ++ file_args
        -- Dump just the opacity mask
        () <- cmd ["convert", alpha, "-alpha", "extract", mask]
        -- Feather the mask to clean up the edges
        cmd ["feather", "-d", show feather_size, mask, mask]

    -- Apply the mask to the final image
    cmd ["convert",  alpha, mask, "-alpha", "Off", "-compose", "CopyOpacity", "-composite", alpha]

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
    let plot = "." </> scriptdir </> "plot.pl"
    need [plot, voteout id]
    cmd [plot, score, history, id, voteout id]

  alphashape "*" %> \file -> do
    let id = (takeFileName . takeBaseName) file
    let alphashape_cmd = "." </> scriptdir </> "alpha_shape"
    let src = tmpdir </> "alpha" </> concat [id, ".mask.png"]
    need [src, alphashape_cmd]
    () <- cmd [alphashape_cmd, file, src]
    cmd ["touch", file]

  phony "all" $ do
    need ([dbfile, outdir </> "tiles" </> "reunion", outdir </> "tiles" </> "all"] ++ all_dags ++ all_charts ++ all_md)
