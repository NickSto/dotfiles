#!/usr/bin/env python3
import argparse
import logging
import random
import sys
from typing import Union, Literal, Optional, NoReturn

DESCRIPTION = """Use the random module from the command line. This emulates the built-in command
line behavior added to the module in Python 3.13."""


def make_argparser():
    parser = argparse.ArgumentParser(add_help=False, description=DESCRIPTION)
    options = parser.add_argument_group('Options')
    options.add_argument('args', nargs='*',
        help='Give multiple arguments to do --choice on them. Give an integer to do --integer or a '
            'float to do --float.')
    options.add_argument('-c', '--choice', nargs='+',
        help='Choose a random item from the provided choices.')
    options.add_argument('-i', '--integer', type=int,
        help='Choose a random integer between 1 and N (inclusive).')
    options.add_argument('-f', '--float', type=float,
        help='Choose a random float between 0 and N (inclusive), from a uniform distribution.')
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


def main(*argv: str) -> Optional[int]:

    parser = make_argparser()
    args = parser.parse_args(argv[1:])

    logging.basicConfig(stream=args.log, level=args.volume, format='%(message)s')

    # Implemented with Copilot:

    # Determine which operation to perform, stored as a single string
    # One of: 'choice', 'integer', 'float', or None
    operation: Literal['choice','integer','float',None] = None

    if args.choice is not None:
        operation = 'choice'
    if args.integer is not None:
        if operation is not None:
            fail(
                'Specify only one of --choice, --integer, or --float (or give positional arguments)'
            )
        operation = 'integer'
    if args.float is not None:
        if operation is not None:
            fail(
                'Specify only one of --choice, --integer, or --float (or give positional arguments)'
            )
        operation = 'float'

    # Implicit behavior from positional args if no explicit operation is given
    if operation is None:
        if not args.args:
            parser.print_help()
            return 0

        if len(args.args) == 1:
            value = args.args[0]
            # Try integer first
            try:
                n_int = int(value)
                operation = 'integer'
                args.integer = n_int
            except ValueError:
                # Then try float
                try:
                    n_float = float(value)
                    operation = 'float'
                    args.float = n_float
                except ValueError:
                    fail(f'Could not interpret argument {value!r} as int or float')
        else:
            # Multiple positional args => implicit choice
            operation = 'choice'
            args.choice = args.args

    if operation is None:
        parser.print_help()
        return 0

    # Execute the chosen operation
    if operation == 'choice':
        if not args.choice:
            fail('No choices provided for --choice')
        logging.info('Choosing from %d options', len(args.choice))
        result = random.choice(args.choice)

    elif operation == 'integer':
        n = args.integer
        if n < 1:
            fail('Upper bound for --integer must be >= 1')
        logging.info('Choosing random integer between 1 and %d (inclusive)', n)
        result = random.randint(1, n)

    elif operation == 'float':
        n = args.float
        logging.info('Choosing random float between 0 and %s (inclusive)', n)
        result = random.uniform(0.0, n)

    else:
        fail(f'Internal error: unknown operation {operation!r}')

    print(result)
    return 0


def fail(error: Union[str,BaseException], code: int = 1) -> NoReturn:
    if __name__ == '__main__':
        logging.critical(f'Error: {error}')
        sys.exit(code)
    elif isinstance(error, BaseException):
        raise error
    else:
        raise RuntimeError(error)


if __name__ == '__main__':
    try:
        sys.exit(main(*sys.argv))
    except BrokenPipeError:
        pass
