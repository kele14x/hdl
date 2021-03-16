import argparse
import logging
import sys
import subprocess
import os

logger = logging.getLogger('main')

default_config = {
    'working_dir': 'build',  # relative path to the folder where .flt file exists
}


def read_flt(filename: str):
    """
    Read and parse a .flt file
    """

    abspath = os.path.abspath(filename)
    logger.info('Read .flt file "%s"', abspath)

    files = []
    with open(abspath, 'r') as flt:
        for line in flt:
            if not line[0] == '#' or not line == '':
                files.append(line)


def call_vivado(args, settings=None):
    if settings:
        (_, ext) = os.path.splitext(settings)
        if ext == '.bat':
            vivado_cmd = 'call {} & vivado'.format(settings)
        elif ext == '.sh':
            vivado_cmd = 'source {} & vivado'.format(settings)
        else:
            logger.error(
                'Wrong configuration of vivado_settings {}'.format(settings))
            sys.exit()
    else:
        vivado_cmd = 'vivado'

    cmd = '{} -nolog -nojournal '.format(vivado_cmd)
    cmd = cmd + ' '.join(args)

    logger.info('Call command \"{}\"'.format(cmd))
    try:
        # shell=True is important here
        output = subprocess.check_output(cmd, shell=True)
    except subprocess.CalledProcessError as e:
        logger.error('Call command error with code {}'.format(e.returncode))
    return output


def get_vivado_version():
    vivado_settings = 'D:\\Xilinx\\Vivado\\2020.2\\settings64.bat'
    output = call_vivado(['-version'], settings=vivado_settings)
    version = output.split()[1][1:]
    # version is bytes string, so decode is needed
    logger.info('Vivado version {}'.format(version.decode()))
    return version


def config_logger():
    formatter = logging.Formatter('[%(asctime)s] [%(name)s] [%(levelname)s] %(message)s')

    handler = logging.StreamHandler()
    handler.setFormatter(formatter)

    logger.addHandler(handler)
    logger.setLevel(logging.DEBUG)


if __name__ == '__main__':

    config_logger()
    logger.info("vbuild starts")

    get_vivado_version()

    # parser = argparse.ArgumentParser()
    # parser.add_argument('infile')
    # args = parser.parse_args(sys.argv)

    # prj = read_flt(args.infile)
