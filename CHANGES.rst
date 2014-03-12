.. default-role:: literal

.. role:: kbd(literal)

0.3 (in development)
--------------------

This version is the first release under new maintenance.

- New features:

  - Imenu support
  - Jump to classes, defines, variables and resources with :kbd:`C-c C-j`
  - Align parameters in a block with :kbd:`C-c C-a`
  - Validate, lint and apply Puppet manifests with :kbd:`C-c C-v`, :kbd:`C-c
    C-l` and :kbd:`C-c C-c`

- Improvements:

  - Fontify all keywords and built-in functions from Puppet 3.4 correctly
  - Do not fontify built-in functions and types as keywords anymore
  - Fontify built-in meta-parameters
  - Fontify the negation operater
  - Fontify C style comments correctly
  - #23: Fontify regular expression literals
  - Fix the syntax classification of characters to improve the fontification and
    sexp-navigation

0.2
---

This and earlier versions were maintained and released by Puppet Labs
