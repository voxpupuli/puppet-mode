Contribution guidelines
=======================

If you discover issues, have ideas for improvements or new features, or want to
contribute a new module, please report them to the [issue tracker][] of the
repository or submit a pull request. Please, try to follow these guidelines when
you do so.

Reporting issues
----------------

- Check that the issue has not already been reported.
- Check that the issue has not already been fixed in the latest code.
- Be clear and precise (do not prose, but name functions and commands exactly).
- Include the version of Puppet Mode, as shown by <kbd>M-x
  puppet-version</kbd>
- Open an issue with a clear title and description in grammatically correct,
  complete sentences.

Contributing code
-----------------

Contributions of code, either as pull requests or as patches, are *very*
welcome, but please respect the following guidelines.

### General

- Write good and *complete* code.
- Provide use cases and rationale for new features.

### Code style

- Generally, use the same coding style and spacing.
- Do not use tabs for indentation.
- Add docstrings for every declaration.
- Make sure your code does not emit byte compiler warnings.
- Make sure your code does not have docstring issues, with <kbd>M-x
  checkdoc-buffer</kbd>, or <kbd>C-c ? d</kbd> if `checkdoc-mode` is enabled

It's recommended that you use [Flycheck][] to avoid byte compiler and checkdoc
warnings.

Commit messages
---------------

Write commit messages according to [Tim Pope's guidelines][guidelines]. In
short:

- Start with a capitalized, short (50 characters or less) summary, followed by a
  blank line.
- If necessary, add one or more paragraphs with details, wrapped at 72
  characters.
- Use present tense and write in the imperative: “Fix bug”, not “fixed bug” or
  “fixes bug”.
- Separate paragraphs by blank lines.
- Do *not* use special markup (e.g. Markdown).  Commit messages are plain text.
  You may use ``*emphasis*`` or ``_underline_`` though, following conventions
  established on mailing lists.

This is a model commit message:

    Capitalized, short (50 chars or less) summary

    More detailed explanatory text, if necessary.  Wrap it to about 72
    characters or so.  In some contexts, the first line is treated as the
    subject of an email and the rest of the text as the body.  The blank
    line separating the summary from the body is critical (unless you omit
    the body entirely); tools like rebase can get confused if you run the
    two together.

    Write your commit message in the imperative: "Fix bug" and not "Fixed bug"
    or "Fixes bug."  This convention matches up with commit messages generated
    by commands like git merge and git revert.

    Further paragraphs come after blank lines.

    - Bullet points are okay, too

    - Typically a hyphen or asterisk is used for the bullet, followed by a
      single space, with blank lines in between, but conventions vary here

    - Use a hanging indent

[Git Commit Mode][] and [Magit][] provide a major mode for Git commit messages,
which helps you to comply to these guidelines.

Pull requests
-------------

- Use a **topic branch** to easily amend a pull request later, if necessary.
- Do **not** open new pull requests, when asked to improve your patch.  Instead,
  amend your commits with `git rebase -i`, and then update the pull request with
  `git push --force`
- Open a [pull request][] that relates to but one subject with a clear title and
  description in grammatically correct, complete sentences.

[issue tracker]: https://github.com/voxpupuli/puppet-mode/issues
[Flycheck]: http://www.flycheck.org
[guidelines]: http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html
[Git Commit Mode]: https://github.com/magit/git-modes/
[Magit]: https://github.com/magit/magit/
[pull request]: https://help.github.com/articles/using-pull-requests
