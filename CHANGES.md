Changes
=======

master (in development)
-----------------------

- New features:

    - Automatic interpolation of variables in double quoted strings when
      pressing <kbd>$</kbd>
    - New interactive command `puppet-toggle-string-quotes` bound to <kbd>C-c
      C-'</kbd>
    - New interactive command `puppet-clear-string` bound to <kbd>C-c C-;</kbd>

- Improvements:

    - Highlight type arguments to `contain`, `include`, and `require` [GH-37]
    - Highlight regular expression literals in valid contexts only [GH-39]
    - `forward-sexp` and friends treat regular expression literals as a single
      expression now [GH-39]

- Bug fixes:

    - Fix fontification of variables referenced from top-scope, e.g. `$::foo`
    - Fix duplicate and misplaced entries in Imenu
    - Fix order of submenus in Imenu
    - Do not parse node names like type names anymore
    - Improve thing at point and some small highlighting glitches by moving `:`
      into symbol syntax [GH-38]
    - Pass proper local file names to commands that run remotely [GH-46]
    - Remember the last `apply` command per buffer [GH-46]

- Miscellaneous:

    - Drop cl-lib dependency
    - Add unit tests for fontification, alignment and Imenu [GH-34]

0.3 (Mar 13, 2014)
------------------

This version is the first release under new maintenance.

- New features:

    - Imenu support [GH-13]
    - Jump to classes, defines, variables and resources with <kbd>C-c C-j</kbd>
      [GH-13]
    - Align parameters in a block with <kbd>C-c C-a</kbd>
    - Validate, lint and apply Puppet manifests with <kbd>C-c C-v</kbd>,
      <kbd>C-c C-l</kbd> and <kbd>C-c C-c</kbd> [GH-11]
    - Move across blocks with <kbd>C-M-a</kbd> and <kbd>C-M-e</kbd>

- Improvements:

    - Fontify all keywords and built-in functions from Puppet 3.4 correctly
    - Do not fontify built-in functions and types as keywords anymore
    - Fontify built-in meta-parameters
    - Fontify the negation operater
    - Fontify C style comments correctly
    - Fontify regular expression literals [GH-23]
    - Fontify variable expansions in double-quoted strings [GH-18]
    - Fontify variable expansions in single-quoted strings [GH-20]
    - Optionally fontify variable references in comments with
      `puppet-fontify-variables-in-comments`
    - Fontify special escape sequences in double-quoted strings [GH-25]
    - Fix the syntax classification of characters to improve the fontification
      and sexp-navigation

0.2
---

This and earlier versions were maintained and released by Puppet Labs
