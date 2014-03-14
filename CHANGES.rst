.. default-role:: literal

.. role:: kbd(literal)

master (in development)
-----------------------

- Drop cl-lib dependency

0.3 (Mar 13, 2014)
------------------

This version is the first release under new maintenance.

- New features:

  - #13: Imenu support
  - #13: Jump to classes, defines, variables and resources with :kbd:`C-c
    C-j`
  - Align parameters in a block with :kbd:`C-c C-a`
  - #11: Validate, lint and apply Puppet manifests with :kbd:`C-c C-v`,
    :kbd:`C-c C-l` and :kbd:`C-c C-c`
  - Move across blocks with :kbd:`C-M-a` and `C-M-e`

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
