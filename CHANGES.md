Changes
=======

master (in development)
-----------------------

- Improvements:

  - #37: Highlight type arguments to `contain`, `include`, and `require`
  - #39: Highlight regular expression literals in valid contexts only
  - #39: `forward-sexp` and friends treat regular expression literals as a
    single expression now
  - Automatic interpolation of variables in double quoted strings.
  - New interactive command `puppet-toggle-string-quotes` bound to <kbd>C-c
    C-'</kbd>.
  - New interactive command `puppet-clear-string` bound to <kbd>C-c C-;</kbd>.

- Bug fixes:

  - Fix fontification of variables referenced from top-scope, e.g. `$::foo`
  - Fix duplicate and misplaced entries in Imenu
  - Fix order of submenus in Imenu
  - Do not parse node names like type names anymore
  - #38: Improve thing at point and some small highlighting glitches by moving
    `:` into symbol syntax
  - #46: Pass proper local file names to commands that run remotely
  - #46: Remember the last `apply` command per buffer

- Miscellaneous:

  - Drop cl-lib dependency
  - #34: Add unit tests for fontification, alignment and Imenu

0.3 (Mar 13, 2014)
------------------

This version is the first release under new maintenance.

- New features:

  - #13: Imenu support
  - #13: Jump to classes, defines, variables and resources with <kbd>C-c
    C-j</kbd>
  - Align parameters in a block with <kbd>C-c C-a</kbd>
  - #11: Validate, lint and apply Puppet manifests with <kbd>C-c C-v</kbd>,
    <kbd>C-c C-l</kbd> and <kbd>C-c C-c</kbd>
  - Move across blocks with <kbd>C-M-a</kbd> and <kbd>C-M-e</kbd>

- Improvements:

  - Fontify all keywords and built-in functions from Puppet 3.4 correctly
  - Do not fontify built-in functions and types as keywords anymore
  - Fontify built-in meta-parameters
  - Fontify the negation operater
  - Fontify C style comments correctly
  - #23: Fontify regular expression literals
  - #18: Fontify variable expansions in double-quoted strings
  - #20: Fontify variable expansions in single-quoted strings
  - Optionally fontify variable references in comments with
    `puppet-fontify-variables-in-comments`
  - #25: Fontify special escape sequences in double-quoted strings
  - Fix the syntax classification of characters to improve the fontification and
    sexp-navigation

0.2
---

This and earlier versions were maintained and released by Puppet Labs
