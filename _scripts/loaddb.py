#!/usr/bin/env python
import sqlite3
import glob
import argparse
import re
import frontmatter
import os
import sys

def find_articles(id, s):
    articles = re.findall("%ARTICLE\[([0-9]+)\]%", s)
    articles = map(lambda x: (id, int(x)), articles)
    return articles

parser = argparse.ArgumentParser(description='Process History into Frontmatter')
parser.add_argument('article_dir', help='article dir')
parser.add_argument('db_loc', help='database location')
args = parser.parse_args()

if os.path.isfile(args.db_loc):
    os.remove(args.db_loc)

if not os.path.isdir(args.article_dir):
    print "%s is not a directory!" % (args.article_dir)
    sys.exit(1)
    
conn = sqlite3.connect(args.db_loc)
conn.row_factory = sqlite3.Row
cur = conn.cursor()

cur.execute("CREATE TABLE conns(id INTEGER PRIMARY KEY ASC, src INTEGER, dst INTEGER, UNIQUE(src, dst) ON CONFLICT IGNORE);")
cur.execute("CREATE TABLE article(id INTEGER PRIMARY KEY ASC, date TEXT, title TEXT, vicpic TEXT, vicpic_small TEXT, article TEXT, blurb TEXT)")
files = glob.glob(args.article_dir + "/*.md")
conns = []
articles = []
for f in files:
    fm = frontmatter.load(f)
    conns = conns + find_articles(fm['id'], fm.content)
    conns = conns + find_articles(fm['id'], fm['blurb'])

    a = (fm['id'], fm['date'], fm['title'], fm['vicpic'], fm['vicpic_small'], fm.content, fm['blurb'])
    articles.append(a)
    
cur.executemany("INSERT INTO conns (src, dst) VALUES (?, ?);", conns)
cur.executemany("INSERT INTO article(id, date, title, vicpic, vicpic_small, article, blurb) VALUES (?, ?, ?, ?, ?, ?, ?);", articles)

conn.commit()
conn.close()
