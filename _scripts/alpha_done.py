#!/usr/bin/env python
import frontmatter
import subprocess
import argparse

parser = argparse.ArgumentParser(description='Process History into Frontmatter')
parser.add_argument('target', help='Target Result Transparent')
parser.add_argument('article_fm', help='Article Markdown FM')
parser.add_argument('alpha_done', help='Already Processed Alpha Done')

args = parser.parse_args()
post = frontmatter.load(args.article_fm)
img = 'img/' + post['vicpic']

subprocess.Popen(
    ["convert",
     img,
     args.alpha_done,
     "-alpha", "Off",
     "-compose", "CopyOpacity",
     "-composite", args.target
     ]
)
