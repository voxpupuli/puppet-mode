Puppet Mode
===========

[![License GPL 3][badge-license]][copying]
[![travis][badge-travis]][travis]

Puppet Mode lets you edit [Puppet][] 3 manifests with [GNU Emacs][] 24.

Puppet Mode is a major mode for [GNU Emacs][] 24 which adds support for the
[Puppet][] language.  Puppet is a system provisioning and configuration tool by
Puppetlabs Inc.  This mode supports Puppet 3 and later.  Puppet 2 is not
explicitly supported anymore, but should mostly work.

This mode needs GNU Emacs 24.  It will **not** work with GNU Emacs 23 and below,
or with other flavors of Emacs (e.g. XEmacs).

Features
--------

1. Syntax highlighting
2. Indentation and alignment of expressions and statements
3. Tag navigation (aka `imenu`)
4. Manual validation and linting of manifests (see [Flycheck][] for on-the-fly
   validation and linting)
5. Integration with [Puppet Debugger][]

Installation
------------

From [MELPA][] or [MELPA Stable][] with <kbd>M-x package-install RET
puppet-mode</kbd>.  Users of Debian ≥11 and derivatives can `sudo apt
install elpa-puppet-mode`.  Manifest validation and linting support is
enabled by installing the `elpa-flycheck` package.

In your [`Cask`][cask] file:

```el
(source melpa)

(depends-on "puppet-mode")
```

Usage
-----

Just visit Puppet manifests.  The major mode is enabled automatically for Puppet
manifests with the extension `.pp`.

The following key bindings are available in Puppet Mode:

Key                | Command
-------------------|--------------------------------------------------
<kbd>C-M-a</kbd>   | Move to the beginning of the current block
<kbd>C-M-e</kbd>   | Move to the end of the current block
<kbd>C-c C-a</kbd> | Align parameters in the current block
<kbd>C-c C-'</kbd> | Toggle string quoting between single and double
<kbd>C-c C-;</kbd> | Blank the string at point
<kbd>C-c C-j</kbd> | Jump to a `class`, `define`, variable or resource
<kbd>C-c C-c</kbd> | Apply the current manifest in dry-run mode
<kbd>C-c C-v</kbd> | Validate the syntax of the current manifest
<kbd>C-c C-l</kbd> | Check the current manifest for semantic issues
<kbd>C-c C-z</kbd> | Launch a puppet-debugger REPL
<kbd>C-c C-r</kbd> | Send the currently marked region to the REPL
<kbd>C-c C-b</kbd> | Send the current buffer to the REPL


For the integration with puppet-debugger to work, the puppet-debugger gem needs
to be installed and available in your `$PATH`.
See [the instructions][puppet debugger install instructions] on
puppet-debugger's repository on how to install it.

Use `M-x customize-group RET puppet` to customize Puppet Mode.

Support
-------

Feel free to ask question or make suggestions in our [issue tracker][].

Contribute
----------

- [Issue tracker][]
- [Github][]

License
-------

Puppet Mode is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

Puppet Mode is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

See [`COPYING`][copying] for the complete license.

[badge-license]: https://img.shields.io/badge/license-GPL_3-green.svg
[COPYING]: https://github.com/voxpupuli/puppet-mode/blob/master/COPYING
[travis]: https://travis-ci.org/voxpupuli/puppet-mode
[badge-travis]: https://travis-ci.org/voxpupuli/puppet-mode.svg?branch=master
[Puppet]: http://docs.puppetlabs.com/
[GNU Emacs]: https://www.gnu.org/software/emacs/
[Flycheck]: http://wwww.flycheck.org
[Puppet Debugger]: https://github.com/nwops/puppet-debugger
[MELPA]: https://melpa.org/
[MELPA Stable]: https://stable.melpa.org
[Cask]: http://cask.github.io/
[puppet debugger install instructions]: https://github.com/nwops/puppet-debugger/#installation
[Issue tracker]: https://github.com/voxpupuli/puppet-mode/issues
[Github]: https://github.com/voxpupuli/puppet-mode
