#!/usr/bin/env python3.8

import argparse
import logging
import sys

from google.cloud import storage


logger = logging.getLogger(__name__)


def download_blob(bucket, path, dest_fname):
    """Downloads a blob from the bucket."""
    storage_cli = storage.Client()
    bucket = storage_cli.bucket(bucket)
    blob = bucket.blob(path)
    blob.download_to_filename(dest_fname)
    logger.info(f'Blob gs://{bucket}/{path} downloaded to {dest_fname}')


def parse_args():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description='RAPT runner')
    parser.add_argument('--data-bucket', dest='data_bucket', default='ncbi-rapt')
    parser.add_argument('--data-path', dest='data_path', default='fake-input-2020-05-10.build0000.tgz')
    return parser.parse_args()


def main():
    logger.info(__name__)

    args = parse_args()

    download_blob(args.data_bucket, args.data_path, 'ref_data.tar.gz')


if __name__ == "__main__":
    sys.exit(main())

