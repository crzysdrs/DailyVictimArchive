#!/usr/bin/python
import sys
import argparse
import frontmatter
import re
import codecs
import glob
import os
import yaml

parser = argparse.ArgumentParser(description='Process Article into Frontmatter')
parser.add_argument('metadir', help='metadir')
parser.add_argument('articledir', help='articledir')
parser.add_argument('redir', help="Redirect File Name")

args = parser.parse_args()

if not os.path.isdir(args.articledir):
    print "%s is not a directory!" % (args.articledir)
    sys.exit(1)

if not os.path.isdir(args.metadir):
    print "%s is not a directory!" % (args.metadir)
    sys.exit(1)

articles = glob.glob(args.articledir + "/*.md")

redir = open(args.redir, "w")
redir.write("RewriteEngine On\n")

conf = yaml.load(open("_config.yml"))

code = 302

redir.write("RewriteBase %s\n" % conf['baseurl'])

for f in articles:
    post = frontmatter.load(f)
    redir.write("RewriteCond %%{QUERY_STRING} ^id=%d$ [NC]\n" % (post['id']))
    redir.write("RewriteRule article.php$ %s? [L,R=%d]\n" % (post['permalink'][1:], code))

meta = glob.glob(args.metadir + "/*.md")

for f in meta:
    post = frontmatter.load(f)
    l = re.sub("\.md$", '', f)
    l = l[1:]
    redir.write("RewriteCond %%{QUERY_STRING} ^id=%d$ [NC]\n" % (post['id']))
    redir.write("RewriteRule meta.php$ %s? [L,R=%d]\n" % (l, code))

boring = {
    'reunion.php':'map/reunion/'
}

for s, t in boring.iteritems():
    redir.write('RewriteRule ^{}$ {} [L,R={code}]\n'.format(s, t, code=code))
