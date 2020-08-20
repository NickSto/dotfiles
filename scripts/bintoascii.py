#!/usr/bin/env python3
import argparse
import logging
import sys
assert sys.version_info.major >= 3, 'Python 3 required'

DESCRIPTION = """Convert binary to ASCII."""


def make_argparser():
  parser = argparse.ArgumentParser(add_help=False, description=DESCRIPTION)
  options = parser.add_argument_group('Options')
  options.add_argument('binary', nargs='*', metavar='011011010111010101100101011100100111010001100101',
    help='Binary bytes to convert to ascii')
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

  if args.binary:
    line = ''.join(args.binary)
    lines = [line]
  else:
    lines = sys.stdin

  for line_raw in lines:
    binstr = line_raw.rstrip('\r\n')
    chars = []
    for i in range(0, len(binstr), 8):
      byte = binstr[i:i+8]
      integer = int(byte, 2)
      chars.append(chr(integer))
    print(''.join(chars), end='')
  print()


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
