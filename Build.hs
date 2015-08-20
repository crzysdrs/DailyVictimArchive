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

sortAndGroup assocs = Map.fromListWith (++) [(k, [v]) | (k, v) <- assocs]

votefile id = concat ["_build/archive/archive.gamespy.com/comics/DailyVictim/vote.asp_id_", id, "_dontvote_true"]
htmlfile id = concat ["_build/archive/archive.gamespy.com/Dailyvictim/index.asp_id_", id, ".html"]
articlefile id = concat [tmpdir, "/", id, ".article"]
mirrorhtml id = concat ["_build/archive/mirror/", id, ".html"]
mirrorvote id = concat ["_build/archive/mirror/", id, ".vote.html"]
historyfile id = concat ["_build/archive/history/", id, ".*.html"]
            
dagfile id = concat [outdir, "/dags/", id, ".png"]
voteout id = concat [tmpdir, "/", id, ".vote"]
         
article_ids = filter (\x -> not (x == 228 || x == 464)) ([10, 11, 13, 14, 15, 16, 17] ++ [19..700])
all_articles = map articlefile (map show article_ids)
all_dags = map dagfile (map show article_ids)
all_votes = map voteout (map show article_ids)

anatomy_html =  map (\x -> concat [mirrordir, x]) $ map (\x -> concat ["/anatofvictim.", show x, ".html"]) [1..5]
top10_html =  map (\x -> concat [mirrordir, x]) $ map (\x -> concat ["/top10.", show x, ".html"]) [1..4]
           
builddir = "_build"
outdir = concat [builddir, "/out"]
tmpdir = concat [builddir, "/tmp"]
dbfile = concat [outdir, "/dv.db"]
mirrordir = "_build/archive/mirror"
archivedir = "_build/archive"

main :: IO ()
main =  
  shakeArgs shakeOptions{shakeFiles="_build",shakeVerbosity=Chatty} $ do
  want["all"]
  
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
         "perlmagick",
         "libcode-tidyall-perl",
         "php-codesniffer",
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

  "gamespy.tar.gz" %> \out -> do
    () <- cmd ["git", "annex", "init"]
    cmd ["git", "annex", "get", "."]

  voteout "*" %> \v -> do
    let id = takeFileName $ dropExtension $ v
    need [archivedir]
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
    removeFilesAfter "" [dbfile]
    cmd ["./loaddb.pl", dbfile, tmpdir, mirrordir]
     
  [archivedir] ++ anatomy_html ++ top10_html &%> \a -> do
    need ["gamespy.tar.gz"]
    () <- cmd ["mkdir", "-p", archivedir]
    cmd ["tar", "xf", "gamespy.tar.gz", "-C", archivedir]
           
  articlefile "*" %> \out -> do
    need [archivedir]
    let id = takeFileName $ dropExtension $ out
    let (html, vote) = if (read id) <= 696
                       then (htmlfile id, Just (votefile id))
                       else (mirrorhtml id, Nothing)
    let vote_str = case vote of
          Just x -> x
          Nothing -> "NO VOTE DATA"     
    need ["article.pl", html]    
    case vote of
      Just v -> need[v]
      Nothing -> return ()
  
    cmd ["./article.pl", articlefile id, id, html, vote_str]

  ["_build/out/dags/*.png", "_build/out/dags/*.map", "_build/out/dags/*.plain"] &%> \[dpng, dmap, dplain] -> do
    let id = takeFileName $ dropExtension $ dpng
    need (["./dag.pl", dbfile] ++ all_articles)
    cmd ["./dag.pl", id]
     
  phony "all" $ do
    need [dbfile]
