CI for Sagittarius Scheme
=========================

This is a CI script for Sagittarius Scheme. This CI is meant to be
executed on local machine for now.

Requirements
------------

The CI is using Vagrant, Virtual Box as its provider. Also the image
files won't be added automatically so before running process, those
files need to be added to the box.


TODO
----

- Don't depend on Vagrant (using `libvirt` and Qemu reduces one dependency).
- Adding more platforms (currently only FreeBSD 12.0 is supported)
- Run this somewhere not local machine.
