# NET
Noninvasive Electrophysiology Toolbox

## Downloading
Please install [Git LFS](https://git-lfs.com/) before cloning this repository
(we use Git LFS for some binary data like the images in the `template/`
folder).

Then just clone:

`git clone https://github.com/bind-group-kul/net.git`

In case you cloned the repository before installing Git LFS, do the
following to retrieve the binary files:

```
git lfs fetch
git lfs checkout
```

## Running
Run the toolbox with the GUI:

`net_start_gui.m`

Run the toolbox through the main script (for programmers only):

`net_start_no_gui.m`

After choosing the destination folder, the excel files with the
processing and analysis parameters will be automatically copied
in that folder.

