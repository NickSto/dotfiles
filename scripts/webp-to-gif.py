#!/usr/bin/env python3
import argparse
import logging
import pathlib
import sys
# Third party
try:
  import PIL.Image
except ImportError:
  print(
    'This requires the Python Imaging Library (or Pillow) to be installed.', file=sys.stderr
  )
  raise

DESCRIPTION = """Convert an animated .webp to a .gif."""


def make_argparser():
  parser = argparse.ArgumentParser(add_help=False, description=DESCRIPTION)
  options = parser.add_argument_group('Options')
  options.add_argument('webp', metavar='image.webp', type=pathlib.Path,
    help='The .webp file.')
  options.add_argument('gif', metavar='image.gif', type=pathlib.Path,
    help='Where to write the .gif output to.')
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

  image = PIL.Image.open(args.webp)
  image.save(args.gif, 'gif', save_all=True, optimize=True, background=0)


def fail(message):
  logging.critical(f'Error: {message}')
  if __name__ == '__main__':
    sys.exit(1)
  else:
    raise Exception(message)


if __name__ == '__main__':
  try:
    sys.exit(main(sys.argv))
  except BrokenPipeError:
    pass
