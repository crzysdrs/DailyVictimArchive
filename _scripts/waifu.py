#!/usr/bin/python
import subprocess
import sys
import argparse
import frontmatter
import re
import codecs
import numpy as np
import cv2
from matplotlib import pyplot as plt
from PIL import Image
import tempfile
import os

def should_use_block(value):
    for c in u"\u000a\u000d\u001c\u001d\u001e\u0085\u2028\u2029":
        if c in value:
            return True
        return False

def str_presenter(dumper, data):
    if should_use_block(data):
        return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='>')
    return dumper.represent_scalar('tag:yaml.org,2002:str', data)

def is_grey_scale(img_path):
    im = Image.open(img_path).convert('RGB')
    w,h = im.size
    for i in range(w):
        for j in range(h):
            r,g,b = im.getpixel((i,j))
            if abs(r-b) + abs(g - b) + abs(g - r) > 10:
                return False
    return True

def imagepath(p):
    if not re.match("^.+\.gif$", p):
        return p

    img = Image.open(p)

    with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as f:
        img.save(f.name)
        f.flush()
        return f.name

waifu_dir = "/home/crzysdrs/proj/waifu2x-converter-cpp/"
waifu2x = waifu_dir + "waifu2x-converter-cpp"

frontmatter.yaml.Dumper.add_representer(unicode, str_presenter)
parser = argparse.ArgumentParser(description='Process Article into Frontmatter')
parser.add_argument('fm_src', help='fm article')
args = parser.parse_args()

scoredate = "2009-12-09 15:45:37"

post = frontmatter.load(args.fm_src)

imgs = ['img/' + post['vicpic_small'], 'img/' + post['vicpic']]

imgs += re.findall("img/[^\]\)]+\.(?:jpe?g|gif)", post['blurb'] + post.content)

def replace_name(post, old, new):
    pattern = r"\b{}\b".format(old)
    post.content = re.sub(pattern, newname, post.content)
    post['vicpic_small'] = re.sub(pattern, newname, post['vicpic_small'])
    post['vicpic'] = re.sub(pattern, newname, post['vicpic'])
    post['blurb'] = re.sub(pattern, newname, post['blurb']).decode('utf-8', 'ignore')


changed = False
for i in imgs:
    stem = re.match("^(.+)\.(?:jpe?g|gif|png)", i)
    if not stem:
        print "Skipping unknown image type  " + i
        continue

    png = stem.group(1) + ".png"
    fname = re.search("/([^/]+)$", i).group(1)

    if re.match("[cC]olor", i):
        pass
    elif os.path.isfile(i) and is_grey_scale(i):
        print "Skipping " + i
    elif os.path.isfile(i) and not os.path.isfile(png):
        print i
        subprocess.call([
            waifu2x,
            "-i", imagepath(i),
            "-o", png,
            "--noise_level", "2",
            "--scale_ratio", "1",
            "--model_dir", waifu_dir + "models"
        ])
        subprocess.call(["git", "rm", i])

    if os.path.isfile(png):
        print fname
        changed = True
        newname = re.sub("\.(jpe?g|gif)$", ".png", fname)
        replace_name(post, fname, newname)

if changed:
    frontmatter.dump(post, args.fm_src, Dumper=frontmatter.yaml.Dumper, allow_unicode=True)
    print "Updated FM " + args.fm_src
