=============
 Puppet Mode
=============

.. default-role:: literal

.. role:: kbd(literal)
   :class: kbd

.. contents:: Table of Contents
   :local:

Puppet Mode is an Emacs major mode for Puppet_ manifests.

.. _Puppet: http://docs.puppetlabs.com/

Features
========

- Syntax highlighting
- Indentation
- Tag navigation (aka `imenu`)
- Validation and linting of manifests

Installation
============

From MELPA_ (recommended) or Marmalade_ with :kbd:`M-x package-install RET
puppet-mode`.

In your Cask_ file:

.. code-block:: lisp

   (source gnu)
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
|:kbd:`C-c C-j` | Jump to a `class`, `define`, variable or resource          |
+---------------+------------------------------------------------------------+
|:kbd:`C-c C-c` | Apply the current manifest with `puppet apply`             |
+---------------+------------------------------------------------------------+
|:kbd:`C-c C-v` | Validate the syntax of the current manifest with `puppet   |
|               | parser validate`                                           |
+---------------+------------------------------------------------------------+
|:kbd:`C-c C-l` | Lint the current manifest with `puppet-lint`               |
+---------------+------------------------------------------------------------+

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
