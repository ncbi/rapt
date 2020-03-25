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
~$ jupyter-notebook --no-browser
[I 23:11:21.695 NotebookApp] Writing notebook server cookie secret to /home/user/.local/share/jupyter/runtime/notebook_cookie_secret
[I 23:11:21.835 NotebookApp] Serving notebooks from local directory: /home/user
[I 23:11:21.835 NotebookApp] The Jupyter Notebook is running at:
[I 23:11:21.835 NotebookApp] http://localhost:8888/?token=28bcb0c90e6407acb3b2533123c28b2925706f638deef638
[I 23:11:21.835 NotebookApp]  or http://127.0.0.1:8888/?token=28bcb0c90e6407acb3b2533123c28b2925706f638deef638
[I 23:11:21.835 NotebookApp] Use Control-C to stop this server and shut down all kernels (twice to skip confirmation).
[C 23:11:21.837 NotebookApp]

    To access the notebook, open this file in a browser:
        file:///home/user/.local/share/jupyter/runtime/nbserver-1955-open.html
    Or copy and paste one of these URLs:
        http://localhost:8888/?token=28bcb0c90e6407acb3b2533123c28b2925706f638deef638
     or http://127.0.0.1:8888/?token=28bcb0c90e6407acb3b2533123c28b2925706f638deef638
```

If you copy and paster the line that begins with "http://localhost:8888/?token=" into your favorite web browser, you should have access to the remote Jupyter server.

### Connecting to a remote Google Cloud Instance

