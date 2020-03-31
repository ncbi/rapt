# RAPT base image

These scripts are used to create a Google Clould virtual machine image which includes preloaded all required software and data to run the RAPT Pipeline. 

## Requirements

* packer
* A JSON file containing the the service account authorization
* Python 3 (Optional, for the `launch_image.py` script only)
  * apache libcloud Python library

## Creating the image

Note that if you are building your own image, you will need to edit these files and change the project_id and point to your own service account JSON file. Build the image using the `build_image.sh` script

## Usage after building

### Google Web Console

Launch an instance using you newly created image. We recommend using a n1-standard-8. After it starts, and you have opened an ssh session, switch to the rapt user account using the command `sudo -i -u rapt`

### Command-line

You can test the image using the script:

```
$ launch_image.py <instance name>
```

provided you have installed the _libcloud_ python package. The script will always launch the latest version of the image. We recommend using a virtual environment. To access the image:

```
$ gcloud compute ssh rapt@<instance name> --ssh-flag="-L localhost:8888:localhost:8888"
```

Note that you might need to set your project using the `--project` option, depending how you have configured your gcloud authorization. The forwarded port will allow you to view the included example Jupyter notebook using a local web broswer, if you start a Jupyter notebook server on the remote instance. We recommend you start the server using tmux to ensure the process is no stopped by an uncertain internet connection.

```
[remote instance]$ tmux
[remote instance]$ jupyter-notebook --no-browser
```

You can then use the provided localhost URL and token directly in your browser to access the server and open the `RAPT.ipynb` file.
