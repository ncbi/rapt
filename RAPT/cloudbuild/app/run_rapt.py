import argparse
import logging

from google.cloud import storage


logger = logging.getLogger(__name__)


def download_blob(gs_url, destination_filename):
    """Downloads a blob from the bucket."""
    storage_client = storage.Client()
    with open(destination_filename) as file_obj:
        client.download_blob_to_file(gs_url, file_obj)
        logger.info(f'Blob {gs_url} downloaded to {destination_file_name}')


def parse_args():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description='RAPT runner')
    parser.add_argument('--data', dest='data_url', default='gs://ncbi-rapt/fake-input-2020-05-10.build0000.tgz')
    return parser.parse_args()


def main():
    logger.info(appname)

    args = parse_args()

    download_blob(args.data_url, 'ref_data.tar.gz')


if __name__ == "__main__":
    sys.exit(main())

