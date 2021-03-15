import configparser
import argparse
import pathlib
import logging
import sys
import subprocess


def read_flt(filename: str):
    """
    Read and parse a .flt file
    """
    path: pathlib.Path
    path = pathlib.Path(filename)
    path.resolve()
    logging.basicConfig(level=logging.INFO)
    logging.info('Read .flt file "%s"', path)

    config = configparser.ConfigParser()
    config.read(path)

    flt = {}
    print(config['file_set']['src_files'].split())

    flt['flt_file_path'] = path.parent
    return flt


def setup(core):
    working_dir: pathlib.Path
    build_dir = working_dir / 'prj'
    if not build_dir.exists():
        build_dir.mkdir()


def call_vivado(vivado, args):
    subprocess.run('vivado -nolog -nojou' + ' '.join(args),
                   shell=True)


if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument('infile')
    args = parser.parse_args(sys.argv)

    prj = read_flt(args.infile)
