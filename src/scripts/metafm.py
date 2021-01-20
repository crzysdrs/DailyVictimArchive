#!/usr/bin/python
import sys
import argparse
import pypandoc
import frontmatter
import json
import re
import codecs
import sqlite3

def should_use_block(value):
    for c in u"\u000a\u000d\u001c\u001d\u001e\u0085\u2028\u2029":
        if c in value:
            return True
        return False

def str_presenter(dumper, data):
    if should_use_block(data):
        return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='>')
    return dumper.represent_scalar('tag:yaml.org,2002:str', data)

def fix(s, title=False):
    s = s.replace(u'\xa0', '&nbsp;')
    s = re.sub(u'([\n\s]|&nbsp;)*$', '\n', s)
    if title:
        s = re.sub('\n*$', '', s)
        
    return s

def yamltitle(s):
    s = re.sub('[^ a-zA-Z0-9]', '', s);
    s = re.sub(' ', '-', s)
    s = s.lower()
    return s

def articlelink(s):
    s = re.sub('article.php\?id=([0-9]+)', '%ARTICLE[\\1]%', s)
    return s

frontmatter.yaml.Dumper.add_representer(unicode, str_presenter)
#parser = argparse.ArgumentParser(description='Process History into Frontmatter')
#parser.add_argument('target', help='target')

#args = parser.parse_args()

con = sqlite3.connect("_build/out/dv.db")
con.row_factory = sqlite3.Row
cur = con.cursor()

cur.execute("select * from meta_article");

r = cur.fetchone()
while r:
    md = pypandoc.convert(r['article'], 'markdown_strict', format='html')
    title_md = pypandoc.convert(r['title'], 'markdown_strict', format='html', extra_args=["--columns", "9999"])

    md = fix(articlelink(md))
    title_md = fix(title_md, title=True)
    
    post = frontmatter.loads("")
    post.content= md
    post['title'] = title_md
    post['date'] = r['date']
    post['author'] = r['author']
    post['id'] = r['id']
    
    f = "_meta/" + r['date'] + "-" + yamltitle(title_md) + ".md"
    out = codecs.open(f, 'w', 'utf-8')
    frontmatter.dump(post, out, Dumper=frontmatter.yaml.Dumper, allow_unicode=True)

    r = cur.fetchone()


