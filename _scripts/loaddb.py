#!/usr/bin/env python
import sqlite3
import glob
import argparse
import re
import frontmatter
import os
import sys
import json
import markdown

def should_use_block(value):
    for c in u"\u000a\u000d\u001c\u001d\u001e\u0085\u2028\u2029":
        if c in value:
            return True
        return False

def str_presenter(dumper, data):
    if should_use_block(data):
        return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='>')
    return dumper.represent_scalar('tag:yaml.org,2002:str', data)

def find_articles(id, s):
    articles = re.findall("%ARTICLE\[([0-9]+)\]%", s)
    articles = map(lambda x: (id, int(x)), articles)
    return articles

def remove_html(s):
    s = re.sub("<.+?>", "", s)
    return s

def remove_p(s):
    s = re.sub("^<p>", "", s)
    s = re.sub("</p>$", "", s)
    return s

frontmatter.yaml.Dumper.add_representer(unicode, str_presenter)
parser = argparse.ArgumentParser(description='Process History into Frontmatter')
parser.add_argument('article_dir', help='article dir')
parser.add_argument('db_loc', help='database location')
parser.add_argument('json', help='json location')
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
json_articles = {}

md = markdown.Markdown()

allimgs = []
missing = []
for f in files:
    fm = frontmatter.load(f)
    conns = conns + find_articles(fm['id'], fm.content)
    conns = conns + find_articles(fm['id'], fm['blurb'])

    a = (fm['id'], fm['date'], fm['title'], fm['vicpic'], fm['vicpic_small'], fm.content, fm['blurb'])

    html_title = remove_p(md.convert(fm['title']))

    json_articles[fm['id']] = {
        'title':fm['title'],
        'title_plain':remove_html(html_title),
        'title_html':html_title,
        'score':fm['score'],
        'vicsmall':fm['vicpic_small'],
        'date':fm['date'],
        'votes':fm['votes'],
    }

    pattern = "img/[^\)\]]+"
    imgs = re.findall(pattern, fm.content)
    imgs += re.findall(pattern, fm['blurb'])
    imgs += ["img/" + fm['vicpic_small']]
    imgs += ["img/" + fm['vicpic']]

    for i in imgs:
        if not os.path.exists(i):
            print "Missing " + f + " " + i
            missing.append(i)

    allimgs += imgs
    articles.append(a)

cur.executemany("INSERT INTO conns (src, dst) VALUES (?, ?);", conns)
cur.executemany("INSERT INTO article(id, date, title, vicpic, vicpic_small, article, blurb) VALUES (?, ?, ?, ?, ?, ?, ?);", articles)

conn.commit()
conn.close()

j = open(args.json, 'w')
j.write(json.dumps(json_articles))
j.close()

print "Missing {}/{} Images".format(len(missing), len(allimgs))

if len(missing) > 0:
    sys.exit(1)
