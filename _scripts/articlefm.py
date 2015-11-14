#!/usr/bin/python
import sys
import argparse
import pypandoc
import frontmatter
import json
import re
import codecs
def should_use_block(value):
    for c in u"\u000a\u000d\u001c\u001d\u001e\u0085\u2028\u2029":
        if c in value:
            return True
        return False

def str_presenter(dumper, data):
    if should_use_block(data):
        return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='>')
    return dumper.represent_scalar('tag:yaml.org,2002:str', data)

def fix(s):
    s = s.replace(u'\xa0', '&nbsp;')
    return s

def yamltitle(s):
    s = re.sub('[^ a-zA-Z0-9]', '', s);
    s = re.sub(' ', '-', s)
    s = s.lower()
    return s

frontmatter.yaml.Dumper.add_representer(unicode, str_presenter)
parser = argparse.ArgumentParser(description='Process Article into Frontmatter')
parser.add_argument('article', help='json article')
parser.add_argument('target', help='target')

args = parser.parse_args()

article = json.load(open(args.article))

md = pypandoc.convert(article['text'], 'markdown_strict', format='html')
blurb_md = pypandoc.convert(article['blurb'], 'markdown_strict', format='html', extra_args=["--columns", "9999"])
title_md = pypandoc.convert(article['title'], 'markdown_strict', format='html', extra_args=["--columns", "9999"])

post = frontmatter.loads("")
post.content= fix(md)
post['blurb'] = fix(blurb_md)
post['title'] = fix(title_md)
post['id'] = int(article['id'])
post['vicpic_small'] = article['vicpic_small']
post['vicpic'] = article['vicpic']
post['date'] = article['date']
post['color'] = bool(int(article['color']))
post['permalink'] = '/%s/%s/' % (post['id'], yamltitle(post['title']))

out = codecs.open(args.target, 'w', 'utf-8')
frontmatter.dump(post, out, Dumper=frontmatter.yaml.Dumper, allow_unicode=True)
