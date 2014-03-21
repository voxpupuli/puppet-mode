=============
 Puppet Mode
=============

.. default-role:: literal

.. role:: kbd(literal)
   :class: kbd

.. image:: https://travis-ci.org/lunaryorn/puppet-mode.svg?branch=master
   :target: https://travis-ci.org/lunaryorn/puppet-mode

Puppet Mode lets you edit Puppet_ 3 manifests with `GNU Emacs`_ 24.

Puppet Mode is a major mode for `GNU Emacs`_ 24 which adds support for the
Puppet_ language.  Puppet is a system provisioning and configuration tool by
Puppetlabs Inc.  This mode supports Puppet 3 and later.  Puppet 2 is not
explicitly supported anymore, but should mostly work.

This mode needs GNU Emacs 24.  It will **not** work with GNU Emacs 23 and below,
or with other flavors of Emacs (e.g. XEmacs).

.. contents:: Table of Contents:
   :local:

.. _Puppet: http://docs.puppetlabs.com/
.. _GNU Emacs: https://www.gnu.org/software/emacs/

Features
========

1. Syntax highlighting
2. Indentation and alignment of expressions and statements
3. Tag navigation (aka `imenu`)
4. Manual validation and linting of manifests (see Flycheck_ for on-the-fly
   validation and linting)

.. _Flycheck: http://flycheck.readthedocs.org/en/latest/

Installation
============

From MELPA_ (recommended) or Marmalade_ with :kbd:`M-x package-install RET
puppet-mode`.

In your Cask_ file:

.. code-block:: lisp

   (source melpa)

   (depends-on "puppet-mode")

.. _MELPA: http://melpa.milkbox.net/
.. _Marmalade: http://marmalade-repo.org/
.. _Cask: http://cask.github.io/

Usage
=====

Just visit Puppet manifests.  The major mode is enabled automatically for Puppet
manifests with the extension `.pp`.

The following key bindings are available in Puppet Mode:

+---------------+------------------------------------------------------------+
|:kbd:`C-M-a`   | Move to the beginning of the current block                 |
+---------------+------------------------------------------------------------+
|:kbd:`C-M-e`   | Move to the endof the current block                        |
+---------------+------------------------------------------------------------+
|:kbd:`C-c C-a` | Align parameters in the current block                      |
+---------------+------------------------------------------------------------+
|:kbd:`C-c C-j` | Jump to a `class`, `define`, variable or resource          |
+---------------+------------------------------------------------------------+
|:kbd:`C-c C-c` | Apply the current manifest with `puppet apply`             |
+---------------+------------------------------------------------------------+
|:kbd:`C-c C-v` | Validate the syntax of the current manifest with `puppet   |
|               | parser validate`                                           |
+---------------+------------------------------------------------------------+
|:kbd:`C-c C-l` | Lint the current manifest with `puppet-lint`               |
+---------------+------------------------------------------------------------+

Use :kbd:`M-x customize-group RET puppet` to customize Puppet Mode.

Support
=======

Feel free to ask question or make suggestions in our `issue tracker`_.

Contribute
==========

- `Issue tracker`_

.. _Issue tracker: https://github.com/lunaryorn/puppet-mode/issues
.. _Github: https://github.com/lunaryorn/puppet-mode

License
=======

Puppet Mode is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

Puppet Mode is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

See COPYING_ for the complete license.

.. _COPYING: https://github.com/lunaryorn/puppet-mode/blob/master/COPYING
