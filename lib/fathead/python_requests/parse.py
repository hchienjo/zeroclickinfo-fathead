#!/usr/bin env python
# -*- coding: utf-8 -*-
from bs4 import BeautifulSoup
from glob import glob
import re
try:
    from urlparse import urljoin
except ImportError:
    from urllib.parse import urljoin


def build_article(h2_parent, page_url):
    '''Builds fathead article entry.

    Accepts h2_parent and extracts title, url, description and code snippets.
    Returns a dict with keys corresponding to output.txt field names
    '''
    h2 = h2_parent.find('h2')
    title = h2.text.replace('¶', '')
    url = h2_parent.find('a').get('href')
    url = urljoin(page_url, url)
    description = ''
    next_sibling = h2.find_next_sibling(text=None)
    while next_sibling:
        if next_sibling.name == 'p':
            description += next_sibling.text
        elif next_sibling.name == 'div':
            pre = next_sibling.find('pre')
            if pre:
                description += "<pre>{0}</pre>".format(pre.text)
        next_sibling = next_sibling.find_next_sibling(text=None)
    description = "<p>{0}</p>".format(description)
    print("Title %s " % title)
    print("URL %s" % url)
    print("Description %s" % description)

for html_file in glob('download/*.html'):
    print("Processing %s" % html_file)
    soup = BeautifulSoup(open(html_file), "html.parser")
    page_url = soup.find('link', attrs={'rel': 'canonical'}).get('href')
    print("Page url %s" % page_url)
    h2s = soup.findAll('h2')
    for h2 in h2s:
        build_article(h2.parent, page_url)
