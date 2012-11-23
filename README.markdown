# Dart Version Manager

## Installation

To install create a folder somewhere in your filesystem with the "`dvm.sh`" file inside it.  I put mine in a folder called "`.dvm`".

Or if you have `git` installed, then just clone it:

    git clone git://github.com/maksimr/dvm.git ~/.dvm

To activate dvm, you need to source it from your bash shell

    . ~/dvm/dvm.sh

I always add this line to my ~/.bashrc or ~/.profile file to have it automatically sources upon login.
Often I also put in a line to use a specific version of dart.

## Usage

To download and install the latest version of dart, do this:

    dvm install latest


And then in any new shell just use the installed version:

    dvm use latest

If you want to see what versions are available:

    dvm ls

To restore your PATH, you can deactivate it.

    dvm deactivate

## Running tests
Tests are written in [Urchin](http://www.urchin.sh). Install Urchin like so.

    wget -O /usr/local/bin https://raw.github.com/scraperwiki/urchin/0c6837cfbdd0963903bf0463b05160c2aecc22ef/urchin
    chmod +x /usr/local/bin/urchin

(Or put it some other place in your PATH.)

There are slow tests and fast tests. The slow tests do things like install dart
and check that the right versions are used. From the root of the dvm git repository,
run the slow tests like this.

    urchin test/slow

Run all of the tests like this

    urchin test
