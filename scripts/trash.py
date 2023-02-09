#!/usr/bin/env python3
import argparse
import logging
import pathlib
import shutil
import sys
import time
# Third party
try:
    import send2trash
except ImportError:
    print('This requires send2trash to be installed.', file=sys.stderr)
    raise

DESCRIPTION = """Send files and directories to the trash."""


def make_argparser():
    parser = argparse.ArgumentParser(add_help=False, description=DESCRIPTION)
    options = parser.add_argument_group('Options')
    options.add_argument('targets', type=pathlib.Path, nargs='+',
        help='The files and/or directories to be trashed.')
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

    try:
        send2trash.send2trash(args.targets)
    except send2trash.TrashPermissionError:
        to_backup_trash(args.targets)
    except OSError as error:
        if (
            error.args and hasattr(error.args[0], 'startswith') and
            error.args[0].startswith('File not found:')
        ):
            raise
        # One failure scenario where we can use an alternative trash:
        #   errno = 30, strerror = 'Read-only file system',
        #   filename = name of trash it tried to make (e.g. b'/panfs/.Trash-13741')
        to_backup_trash(args.targets)


def to_backup_trash(targets):
    trash_path = pathlib.Path('~/.trash').expanduser()
    logging.warning(f'Resorting to backup trash {trash_path}')
    ensure_backup_trash(trash_path)
    place_targets(targets, trash_path)


def ensure_backup_trash(trash_path):
    if trash_path.exists():
        if not is_our_trash(trash_path):
            fail()
    else:
        make_our_trash(trash_path)


def make_our_trash(trash_dir):
    trash_dir.mkdir(parents=True)
    trash_sentinel = trash_dir/'.backup-trash-directory'
    with trash_sentinel.open('w') as trash_file:
        print('Made by my trash.py', file=trash_file)


def is_our_trash(trash_dir):
    # pylint: disable=logging-fstring-interpolation
    if not trash_dir.is_dir():
        logging.error(
            f'Something (not a directory) already exists at the backup trash path {trash_dir!r}'
        )
        return False
    trash_sentinel = trash_dir/'.backup-trash-directory'
    if not trash_sentinel.is_file():
        logging.error(f'{trash_dir!r} already exists but is missing {trash_sentinel.name!r}')
        return False
    with trash_sentinel.open() as trash_file:
        contents = trash_file.read().strip()
    if contents != 'Made by my trash.py':
        logging.error(f'{trash_dir!r} exists but the contents of {trash_sentinel.name!r} are wrong')
        return False
    return True


def place_targets(targets, trash_dir):
    timestamp = str(time.time())
    time_dir = trash_dir/timestamp
    for target in targets:
        dest_path = trash_dir/target.name
        if dest_path.exists():
            time_dir.mkdir(exist_ok=True, parents=True)
            dest_path = time_dir/target.name
        shutil.move(target, dest_path)


def fail(message=None):
    if message is not None:
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
