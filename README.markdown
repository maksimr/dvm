# Dart Version Manager

![Dartlang](https://raw.github.com/maksimr/dvm/master/dart-logo.png)

Dart Version Manager inspired by [nvm](https://github.com/creationix/nvm)

## Installation

To install create a folder somewhere in your filesystem with the "`dvm.sh`" file inside it.  I put mine in a folder called "`.dvm`".

Or if you have `git` installed, then just clone it:

    git clone git://github.com/maksimr/dvm.git ~/.dvm

To activate dvm, you need to source it from your bash shell

    . ~/.dvm/dvm.sh

I always add this line to my ~/.bashrc or ~/.profile file to have it automatically sources upon login.
Often I also put in a line to use a specific version of dart.

## Usage

To download and install the v0.2.0 release of dart, do this:

    dvm install 0.2.0

And then in any new shell just use the installed version:

    dvm use 0.2.0

Or you can just run it:

    dvm run 0.2.0

If you want to see what versions are available:

    dvm ls

If you want to see what remote versions are available:

    dvm ls-remote

To restore your PATH, you can deactivate it.

    dvm deactivate

To set a default Dart version to be used in any new shell, use the alias 'default':

    dvm alias default 0.2.0

## Running tests
Tests are written in [Urchin](http://www.urchin.sh). Install Urchin like so.

    wget -O /usr/local/bin https://raw.github.com/scraperwiki/urchin/0c6837cfbdd0963903bf0463b05160c2aecc22ef/urchin
    chmod +x /usr/local/bin/urchin

(Or put it some other place in your PATH.)

Run the slow tests like this.

    urchin test/slow
