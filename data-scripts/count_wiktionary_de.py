#!/usr/bin/env python3

import os
import sys
import operator
import re

def usage():
    return '''
This script extracts words and counts from Matthias Buchmeier's 2009 word frequency study over
German television and movies. To use, first visit the study and download, as .html files, as many
of the frequency lists as you want to include in the corpus (each batch contains 5000 words):

https://en.wiktionary.org/wiki/Wiktionary:Frequency_lists#German

Put those into a single directory and point it to this script:

%s wiktionary_html_dir ../data/de_tv_and_film.txt

output.txt will include one line per word in the study, ordered by rank, of the form:

word1 count1
word2 count2
...
    ''' % sys.argv[0]

TRIM_LEADING_WHITESPACE_AND_TAGS_RE = re.compile(r'^(\s*<[^>]*>)+')

EXTRACT_COUNT_AND_TOKEN_RE = re.compile(r'\s*(\d+)\s*<a[^>]*>\s*(\S+)\s*<\/a>')

HAS_UMLAUTS_RE = re.compile(r'[äöüß]')

def parse_wiki_tokens(html_doc_str):
    results = []
    unformatted_list = ''
    num_tokens = 0
    for line in html_doc_str.split('\n'):
        # The list is contained in a single, long line.
        if len(line) > 50000:
            unformatted_list = re.sub(TRIM_LEADING_WHITESPACE_AND_TAGS_RE, '', line)
            break

    for count_and_token_match in EXTRACT_COUNT_AND_TOKEN_RE.finditer(unformatted_list):
        num_tokens += 1
        count = int(count_and_token_match.group(1))
        token = count_and_token_match.group(2)
        # Some tokens contain HTML tags and quotes used for subtitle styling. We just skip them.
        if '<' in token or '\'' in token:
            continue
        new_records = [(normalized, count) for normalized in resolve_umlauts(token)]
        results.extend(new_records)

    # Each batch has ~5000 entries.
    assert 4990 < num_tokens < 5010
    return results

def resolve_umlauts(token):
    normalized = token.lower()
    if not HAS_UMLAUTS_RE.search(normalized):
        return [normalized]
    else:
        normalized_ae = (normalized
            .replace('ä', 'ae')
            .replace('ö', 'oe')
            .replace('ü', 'ue')
            .replace('ß', 'ss'))
        normalized_a = (normalized
            .replace('ä', 'a')
            .replace('ö', 'o')
            .replace('ü', 'u')
            .replace('ß', 's'))
        return [normalized, normalized_a, normalized_ae]


def main(wiktionary_html_root, output_filename):
    token_count = [] # list of pairs
    for filename in os.listdir(wiktionary_html_root):
        path = os.path.join(wiktionary_html_root, filename)
        with open(path, 'r', encoding='utf8') as f:
            token_count.extend(parse_wiki_tokens(f.read()))
    token_count.sort(key=operator.itemgetter(1), reverse=True)
    with open(output_filename, 'w', encoding='utf8') as f:
        for token, count in token_count:
            f.write('{:30} {}\n'.format(token, count))

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(usage())
    else:
        main(*sys.argv[1:])
    sys.exit(0)
