#!/usr/bin/python
import sys
import argparse
import frontmatter
import re
import codecs
import sqlite3

def yamltitle(s):
    s = re.sub('[^ a-zA-Z0-9]', '', s);
    s = re.sub(' ', '-', s)
    s = s.lower()
    return s

def get_score(fm, date):
    score = 0
    count = 0
    history_date = filter(lambda d: d['date'] == date, fm['history'])
    if len(history_date) == 1:
        scores = history_date[0]['votes'];
        scores = zip(range(1,11), scores)
        for (key, val) in scores:
            score += int(key) * int(val)
            count += int(val)
        score /= float(count)

    return (score, count)

parser = argparse.ArgumentParser(description='Process Article into Frontmatter')
parser.add_argument('fm_src', help='fm article')
parser.add_argument('db', help='db')
parser.add_argument('fm_target', help='fm target article')

args = parser.parse_args()

scoredate = "2009-12-09 15:45:37"

conn = sqlite3.connect(args.db)
conn.row_factory = sqlite3.Row
cur = conn.cursor()

post = frontmatter.load(args.fm_src)
froms = cur.execute("SELECT * FROM conns WHERE src = ?;", (post['id'],)).fetchall()
tos = cur.execute("SELECT * FROM conns WHERE dst = ?;", (post['id'],)).fetchall()

score = get_score(post, scoredate)
post['permalink'] = '/victim/%s/%s/' % (post['id'], yamltitle(post['title']))
post['score'] = round(score[0], 2)
post['votes'] = score[1]
post['outlinks'] = map(lambda r : r['dst'], froms)
post['inlinks'] = map(lambda r : r['src'], tos)

out = open(args.fm_target, 'w')
frontmatter.dump(post, out)
