# Using RAPT via Jupyter

This Jupyter notebook is intended to show you how to run RAPT on your own machine. Note that Jupyter is not required, we are merely using for the convience of interleaving documentation with the shell commands. You can view the notebook in GitHub, and copy-n-paste the commands into a Linux commandline.

## Requirements
To run the PGAP pipeline you will need:

* Python (version 3.5 or higher),
* the ability to run Docker (see https://docs.docker.com/install/ if it is not already installed),
* about 100GB of storage for the supplemental data and working space,
* and 2GB-4GB of memory available per CPU used by your container.
* Debian 10 is currently not supported.
* The CPU must have SSE 4.2 support (released in 2008).

The Jupyter notebook is intended to run using the bash kernel, instead of Python. To install the bash kernel, if it is not already:

```bash
$ pip install bash_kernel
$ python -m bash_kernel.install
```

Then select Bash from the Kernel->Change Kernel menu item.

## Running Jupyter remotely

If you are not running Jupyter on your localhost, then accessing the server securely will be an issue. We recommend using port forwarding over ssh.

```bash
~$ ssh -L localhost:8888:localhost:8888 <remote host>
[remote host]~$ jupyter-notebook --no-browser
```

If you copy and paste the line that begins with "http://localhost:8888/?token=" into your favorite web browser, you should have access to the remote Jupyter server.

### Connecting to a remote Google Cloud Instance

Note that the following is supported under Linux, OSX, and Windows. To install the Google Cloud SDK, see https://cloud.google.com/storage/docs/gsutil_install

If you have not yet configured your setup, use `gcloud init` to authenticate, and set your default project.

```bash
~$ gcloud compute ssh <instance name> --ssh-flag="-L localhost:8888:localhost:8888"
[remote host]~$ jupyter-notebook --no-browser
```

Note that you might need the project flag (`--project <project-name>`) if it is different from your default project.
