#!/usr/bin/env python3
import argparse
import logging
import random
import sys
import urllib.parse
assert sys.version_info.major >= 3, 'Python 3 required'

DESCRIPTION = """Split the query parameters off a url."""


def make_argparser():
  parser = argparse.ArgumentParser(add_help=False, description=DESCRIPTION)
  options = parser.add_argument_group('Options')
  options.add_argument('url', nargs='?',
    help='The url. Omit to read from stdin.')
  options.add_argument('-m', '--max-key-width', type=int, default=20,
    help='Maximum width of the key column. Default: %(default)s')
  options.add_argument('-h', '--help', action='help',
    help='Print this argument help text and exit.')
  logs = parser.add_argument_group('Logging')
  logs.add_argument('-l', '--log', type=argparse.FileType('w'), default=sys.stderr,
    help='Print log messages to this file instead of to stderr. Warning: Will overwrite the file.')
  volume = logs.add_mutually_exclusive_group()
  volume.add_argument('-q', '--quiet', dest='volume', action='store_const', const=logging.CRITICAL,
    default=logging.WARNING)
  volume.add_argument('-v', '--verbose', dest='volume', action='store_const', const=logging.INFO)
  volume.add_argument('-D', '--debug', dest='volume', action='store_const', const=logging.DEBUG)
  return parser


def main(argv):

  parser = make_argparser()
  args = parser.parse_args(argv[1:])

  logging.basicConfig(stream=args.log, level=args.volume, format='%(message)s')

  if args.url is not None:
    url = args.url
  else:
    url = sys.stdin.readline()

  parts = url.split('?')
  base = parts[0]
  query = None
  if len(parts) > 1:
    query = '?'.join(parts[1:])

  print(base)
  if query is None:
    return

  params = []
  for param in query.split('&'):
    params.append(parse_param(param))

  max_key_width = 0
  for key, value in params:
    key_width = len(key)
    if key_width <= args.max_key_width:
      max_key_width = max(key_width, max_key_width)


  for key, value in params:
    key_str = (key+':').ljust(max_key_width+1, ' ')
    if len(key_str) <= max_key_width+1:
      sep = ' '
    else:
      sep = '\t'
    print(f'{key_str}{sep}{value}')


def parse_param(param_str):
  fields = param_str.split('=')
  key = fields[0]
  value = ''
  if len(fields) > 1:
    value = '='.join(fields[1:])
  return key, urllib.parse.unquote(value)


def fail(message):
  logging.critical('Error: '+str(message))
  if __name__ == '__main__':
    sys.exit(1)
  else:
    raise Exception(message)


if __name__ == '__main__':
  try:
    sys.exit(main(sys.argv))
  except BrokenPipeError:
    pass
