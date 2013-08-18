## Synopsis

`puppet-mode` is a major Emacs mode, that provides proper font-locking
and indentation support for editing
[Puppet](http://docs.puppetlabs.com/) manifests.

## Installation

### Manual

Just drop `puppet-mode.el` somewhere in your `load-path`. The
`~/.emacs.d/vendor` folder is one popular place for that:

```lisp
(add-to-list 'load-path "~/emacs.d/vendor")
(require 'puppet-mode)
```

### Marmalade

The version of puppet-mode on [Marmalade](http://marmalade-repo.org/)
is out of date. We'll take steps to provide an up-to-date version
there soon.

### MELPA (recommended)

puppet-mode is available on the [MELPA](http://melpa.milkbox.net/)
repository. Installing it from there is highly recommended.

<kbd>M-x package-install RET puppet-mode</kbd>

## Usage

Just open a Puppet manifest (a file ending with the `.pp` extension)
in Emacs and you're in business.

## Known issues

Check out the project's
[issue tracker](https://github.com/lunaryorn/puppet-mode/issues?sort=created&direction=desc&state=open)
for a list of unresolved issues. By the way - feel free to fix any of
them and send a pull request our way. :-)

## Contributors

Here's a [list](https://github.com/lunaryorn/puppet-mode/contributors)
of all the people who have contributed to the development of
puppet-mode.

## Bugs & Improvements

Bug reports and suggestions for improvements are always
welcome. GitHub pull requests are even better! :-)
