# -*- coding: utf-8 -*-
import argparse
import json

def get_file_content(path):
  with open(path) as content_file:
    return content_file.read()
  return None

def get_known_words(path):
  content = get_file_content(path)
  if content != None:
    return content.splitlines()
  return None

def get_new_words(path):
  content = get_file_content(path)
  if content != None:
    rows = json.loads(content)
    words = []
    for row in rows:
      words += row['ZWORDDATA'].encode('utf8').split('§')
    return filter(None, words)
  return None

def write_words(words, path):
  with open(path, 'w') as content_file:
    content_file.write('\n'.join(words))

if __name__ == "__main__":
  parser = argparse.ArgumentParser(description='Append new words to existing list of known Wordbase words.')
  parser.add_argument('-w', '--words', required=True, help='Path to JSON export of Wordbase SQLite WBGAMEBOARD table (Possibly created using the SQLite Professional app)')
  parser.add_argument('-b', '--brain', required=True, help='Path to file containing existing words')
  args = parser.parse_args()
  known_words = get_known_words(args.brain)
  new_words = get_new_words(args.words)
  all_words = list(set(known_words) | set(new_words))
  all_words.sort()
  write_words(all_words, args.brain)
  print 'Already knew %s words. Aadded %s words and now knows %s words' % (len(known_words), len(all_words) - len(known_words), len(all_words))
