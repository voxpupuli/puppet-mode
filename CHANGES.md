Changes
=======

0.4 (Apr 14, 2020)
------------------

- New features:

    - Automatic interpolation of variables in double quoted strings when
      pressing <kbd>$</kbd>
    - New interactive command `puppet-toggle-string-quotes` bound to <kbd>C-c
      C-'</kbd>
    - New interactive command `puppet-clear-string` bound to <kbd>C-c C-;</kbd>
    - Uniform region alignment
    - Add basic support for working with puppet-repl [GH-68]
    - New function `puppet-in-argument-list`.  At any point in an argument
      list, return the position of the list's opening '('

- Improvements:

    - Highlight type arguments to `contain`, `include`, and `require` [GH-37]
    - Highlight regular expression literals in valid contexts only [GH-39]
    - `forward-sexp` and friends treat regular expression literals as a single
      expression now [GH-39]
    - Add prefix arg support to puppet-interpolate
    - Document puppet-debugger integration
    - Make puppet-in-array understand brackets in comments
    - Add Emacs 25.2 to the test matrix [GH-101]
    - Update keywords, functions and metaparameters to Puppet 5.3 [GH-106]
    - Add Puppet 4 data types [GH-107]
    - Add support for indentation of argument lists [GH-112]
    - Add keywords and types for Puppet Bolt [GH-114]
    - Replace deprecated linenumber option in puppet-lint format

- Bug fixes:

    - Fix fontification of variables referenced from top-scope, e.g. `$::foo`
    - Fix duplicate and misplaced entries in Imenu
    - Fix order of submenus in Imenu
    - Do not parse node names like type names anymore
    - Improve thing at point and some small highlighting glitches by moving `:`
      into symbol syntax [GH-38]
    - Pass proper local file names to commands that run remotely [GH-46]
    - Remember the last `apply` command per buffer [GH-46]
    - Take the syntactic context at the right position in
      puppet-syntax-propertize-match
    - Add pcase fix for emacs 24.1
    - Do not set require-final-newline [GH-52]
    - Fix multi-line indentation
    - Fix indentation of function arguments [GH-60, GH-64]
    - Ignore commented out lines when aligning [GH-75]
    - Add missing requirements to fix byte compiler warnings
    - Add missing second argument for ‘looking-back
    - Update puppet-repl-command to use new executable named "puppet debugger"
      [GH-82]
    - Fix binding repl-args when calling make-comint
    - Fix indentation after comments ending with a colon
    - Fix indent handling of class params closing paren [GH-90]
    - Make indent recognize closing braces with commas [GH-88]
    - Skip nested block when aligning [GH-92]
    - Handle aligning nested block before point [GH-93]
    - Fix infinite loop when indenting defined type [GH-77]
    - Fix indentation of hanging "} ->". [GH-65]
    - Fix indentation of closing braces [GH-104]
    - Prevent comments from changing the indentation level [GH-113]

- Miscellaneous:

    - Drop cl-lib dependency
    - Add unit tests for fontification, alignment and Imenu [GH-34]
    - Replace Marmalade with MELPA Stable for stable releases
    - Address style comments, remove unnecessary progns.
    - Fix test runs
    - Update links to point to voxpupuli
    - Update links to Flycheck website
    - Update MELPA links
    - Added failing test for alignment of nested blocks

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
