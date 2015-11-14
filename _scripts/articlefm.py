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
parser = argparse.ArgumentParser(description='Process Article into Frontmatter')
parser.add_argument('article', help='json article')
parser.add_argument('votes', help='vote json history')
parser.add_argument('target', help='target')

args = parser.parse_args()

article = json.load(open(args.article))
votes = json.load(open(args.votes))

md = pypandoc.convert(article['text'], 'markdown_strict', format='html')
blurb_md = pypandoc.convert(article['blurb'], 'markdown_strict', format='html', extra_args=["--columns", "9999"])
title_md = pypandoc.convert(article['title'], 'markdown_strict', format='html', extra_args=["--columns", "9999"])

title_md = fix(title_md, title=True)
blurb_md = fix(articlelink(blurb_md))
md = fix(articlelink(md))

scoredate = "2009-12-09 15:45:37"
score = 0
history = []
count = 0
if scoredate in votes['votes']:
    scores = votes['votes'][scoredate]
    for key, val in scores.iteritems():
        score += int(key) * int(val)
        count += int(val)
    score /= float(count)

    for date, datevotes in sorted(votes['votes'].iteritems()):    
        date_scores = []
        for i in range(1, 11):
            if str(i) in datevotes:
                date_scores.append(int(datevotes[str(i)]))
            else:
                date_scores.append(0)            

        history.append({
            'date':date,
            'votes':date_scores
        })
        
        
post = frontmatter.loads("")
post.content= md
post['blurb'] = blurb_md
post['title'] = title_md
post['id'] = int(article['id'])
post['vicpic_small'] = article['vicpic_small']
post['vicpic'] = article['vicpic']
post['date'] = article['date']
post['color'] = bool(int(article['color']))
post['permalink'] = '/%s/%s/' % (post['id'], yamltitle(post['title']))
post['score'] = round(score, 2)
post['votes'] = count
post['history'] = history

out = codecs.open(args.target, 'w', 'utf-8')
frontmatter.dump(post, out, Dumper=frontmatter.yaml.Dumper, allow_unicode=True)
