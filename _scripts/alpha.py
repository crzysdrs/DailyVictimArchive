#!/usr/bin/env python
import frontmatter
import argparse
from PIL import Image
import os
import sys
import subprocess
import operator

thresholds = {
    '10':0.2,
    '11':0.05,
    '15':0.2,
    '25':0.1,
    '26':0.1,
    '27':0.1,
    '28':0.05,
    '29':0.05,
    '34':0.2,
    '38':0.5,
    '42':0.7,
    '46':0.5,
    '206':0.4,
    '599':0.4,
    '625':0.2,
    '696':10/255.0,
}

parser = argparse.ArgumentParser(description='Process History into Frontmatter')
parser.add_argument('target', help='Target Result Transparent')
parser.add_argument('article_fm', help='Article Markdown FM')
parser.add_argument('alpha_data', help='Alpha Data for Flood Fills')
parser.add_argument('--if_exists', help='Override Article Vicpic')

args = parser.parse_args()
post = None
threshold = 0.5

if os.path.isfile(args.if_exists):
    img = args.if_exists
else:
    post = frontmatter.load(args.article_fm)
    img = "img/" + post['vicpic']
    
if not os.path.isfile(img):
    print "%s does not exist!" % img
    sys.exit(1)

if args.if_exists == img:
    threshold = 0.5
elif post['id'] in thresholds:
    threshold = thresholds[post['id']]
elif int(post['id']) <= 48:
    threshold = 10 / 255.0
else:
    threshold = 0.5
        
threshold *= 100

im = Image.open(img)
w = im.size[0] - 1
matte = "matte %s floodfill"

floods = []
floods.append(matte % ("%d,%d" % (w, 0)))
floods.append(matte % ("%d,%d" % (0, 0)))

if os.path.isfile(args.alpha_data):
    f = open(args.alpha_data)
    for l in f.readlines():
        floods.append(matte % (l))

flood_list = []        
for d in floods:
    flood_list += ['-draw', d]

subprocess.Popen(
    ['convert',
     img,
     '-alpha', 'set',
     '-channel', 'RGBA',
     '-fuzz', "%s%%" % (threshold),
     '-fill', 'none'     
    ] + flood_list + ['-shave', '1x1'] + [args.target]
)

