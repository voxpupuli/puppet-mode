;;; puppet-mode.el --- Major mode for Puppet manifests  -*- lexical-binding: t; -*-

;; Copyright (C) 2013, 2014  Sebastian Wiesner <lunaryorn@gmail.com>
;; Copyright (C) 2013  Bozhidar Batsov <bozhidar@batsov.com>
;; Copyright (C) 2011  Puppet Labs Inc

;; Author: Russ Allbery <rra@stanford.edu>
;; Maintainer: Sebastian Wiesner <lunaryorn@gmail.com>
;; Maintainer: Bozhidar Batsov <bozhidar@batsov.com>
;; URL: https://github.com/lunaryorn/puppet-mode
;; Keywords: languages
;; Version: 0.2
;; Package-Requires: ((emacs "24.1"))

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; This file incorporates work covered by the following copyright and
;; permission notice:

;;   Licensed under the Apache License, Version 2.0 (the "License"); you may not
;;   use this file except in compliance with the License.  You may obtain a copy
;;   of the License at
;;
;;       http://www.apache.org/licenses/LICENSE-2.0
;;
;;   Unless required by applicable law or agreed to in writing, software
;;   distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
;;   WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
;;   License for the specific language governing permissions and limitations
;;   under the License.

;;; Commentary:

;; Major mode for Puppet manifests

;;; Code:


;;;; Compatibility
(eval-and-compile
  ;; `defvar-local' for Emacs 24.2 and below
  (unless (fboundp 'defvar-local)
    (defmacro defvar-local (var val &optional docstring)
      "Define VAR as a buffer-local variable with default value VAL.
Like `defvar' but additionally marks the variable as being automatically
buffer-local wherever it is set."
      (declare (debug defvar) (doc-string 3))
      `(progn
         (defvar ,var ,val ,docstring)
         (make-variable-buffer-local ',var))))

  ;; `setq-local' for Emacs 24.2 and below
  (unless (fboundp 'setq-local)
    (defmacro setq-local (var val)
      "Set variable VAR to value VAL in current buffer."
      `(set (make-local-variable ',var) ,val))))


;;;; Requirements
(require 'rx)
(require 'align)


;;;; Customization
(defgroup puppet nil
  "Puppet mastering in Emacs"
  :prefix "puppet-"
  :group 'languages
  :link '(url-link :tag "Github" "https://github.com/lunaryorn/puppet-mode")
  :link '(emacs-commentary-link :tag "Commentary" "puppet-mode"))

(defcustom puppet-indent-level 2
  "Indentation of Puppet statements."
  :type 'integer
  :group 'puppet
  :safe 'integerp)

(defcustom puppet-include-indent 2
  "Indentation of continued Puppet include statements."
  :type 'integer
  :group 'puppet
  :safe 'integerp)

(defcustom puppet-indent-tabs-mode nil
  "Indentation can insert tabs in puppet mode if this is non-nil."
  :type 'boolean
  :group 'puppet
  :safe 'booleanp)

(defcustom puppet-comment-column 32
  "Indentation column of comments."
  :type 'integer
  :group 'puppet
  :safe 'integerp)

(defcustom puppet-validate-command "puppet parser validate --color=false"
  "Command to validate the syntax of a Puppet manifest."
  :type 'string
  :group 'puppet)

(defcustom puppet-lint-command
  (concat
   "puppet-lint --with-context "
   "--log-format \"%{path}:%{linenumber}: %{kind}: %{message} (%{check})\"")
  "Command to lint a Puppet manifest."
  :type 'string
  :group 'puppet)

(defcustom puppet-apply-command "puppet apply --verbose --noop"
  "Command to apply a Puppet manifest."
  :type 'string
  :group 'puppet)


;;;; Checking

(defvar-local puppet-last-validate-command nil
  "The last command used for validation.")

(defvar-local puppet-last-lint-command nil
  "The last command used for linting.")

;; This variable is intentionally not buffer-local, since you typically only
;; apply top-level manifests, but not class or type definitions.
(defvar puppet-last-apply-command nil
  "The last command used to apply a manifest.")

(defun puppet-run-check-command (command buffer-name-template)
  "Run COMMAND to check the current buffer."
  (save-some-buffers (not compilation-ask-about-save) nil)
  (compilation-start command nil (lambda (_)
                                   (format buffer-name-template command))))

(defun puppet-read-command (prompt previous-command default-command)
  "Read a command from minibuffer with PROMPT."
  (let ((filename (or (buffer-file-name) "")))
    (read-string prompt (or previous-command
                            (concat default-command " "
                                    (shell-quote-argument filename))))))

(defun puppet-validate (command)
  "Validate the syntax of the current buffer with COMMAND.

When called interactively, prompt for COMMAND."
  (interactive (list (puppet-read-command "Validate command: "
                                          puppet-last-validate-command
                                          puppet-validate-command)))
  (setq puppet-last-validate-command command)
  (puppet-run-check-command command "*Puppet Validate: %s*"))

(defun puppet-lint (command)
  "Lint the current buffer with COMMAND.

When called interactively, prompt for COMMAND."
  (interactive (list (puppet-read-command "Lint command: "
                                          puppet-last-lint-command
                                          puppet-lint-command)))
  (setq puppet-last-lint-command command)
  (puppet-run-check-command command "*Puppet Lint: %s*"))

(defun puppet-apply (command)
  "Apply the current manifest with COMMAND.

When called interactively, prompt for COMMAND."
  (interactive (list (puppet-read-command "Apply command: "
                                          puppet-last-apply-command
                                          puppet-apply-command)))
  (setq puppet-last-apply-command command)
  (puppet-run-check-command command "*Puppet Apply: %s*"))


;;;; Indentation code
(defun puppet-comment-line-p ()
  "Return non-nil iff this line is a comment."
  (save-excursion
    (save-match-data
      (beginning-of-line)
      (looking-at (format "\\s-*%s" comment-start)))))

(defun puppet-block-indent ()
  "If point is in a block, return the indentation of the first line of that
block (the line containing the opening brace).  Used to set the indentation
of the closing brace of a block."
  (save-excursion
    (save-match-data
      (let ((opoint (point))
            (apoint (search-backward "{" nil t)))
        (when apoint
          ;; This is a bit of a hack and doesn't allow for strings.  We really
          ;; want to parse by sexps at some point.
          (let ((close-braces (count-matches "}" apoint opoint))
                (open-braces 0))
            (while (and apoint (> close-braces open-braces))
              (setq apoint (search-backward "{" nil t))
              (when apoint
                (setq close-braces (count-matches "}" apoint opoint))
                (setq open-braces (1+ open-braces)))))
          (if apoint
              (current-indentation)
            nil))))))

(defun puppet-in-array ()
  "If point is in an array, return the position of the opening '[' of
that array, else return nil."
  (save-excursion
    (save-match-data
      (let ((opoint (point))
            (apoint (search-backward "[" nil t)))
        (when apoint
          ;; This is a bit of a hack and doesn't allow for strings.  We really
          ;; want to parse by sexps at some point.
          (let ((close-brackets (count-matches "]" apoint opoint))
                (open-brackets 0))
            (while (and apoint (> close-brackets open-brackets))
              (setq apoint (search-backward "[" nil t))
              (when apoint
                (setq close-brackets (count-matches "]" apoint opoint))
                (setq open-brackets (1+ open-brackets)))))
          apoint)))))

(defun puppet-in-include ()
  "If point is in a continued list of include statements, return the position
of the initial include plus puppet-include-indent."
  (save-excursion
    (save-match-data
      (let ((include-column nil)
            (not-found t))
        (while not-found
          (forward-line -1)
          (cond
           ((bobp)
            (setq not-found nil))
           ((looking-at "^\\s-*include\\s-+.*,\\s-*$")
            (setq include-column
                  (+ (current-indentation) puppet-include-indent))
            (setq not-found nil))
           ((not (looking-at ".*,\\s-*$"))
            (setq not-found nil))))
        include-column))))

(defun puppet-indent-line ()
  "Indent current line as puppet code."
  (interactive)
  (beginning-of-line)
  (if (bobp)
      (indent-line-to 0)                ; First line is always non-indented
    (let ((not-indented t)
          (array-start (puppet-in-array))
          (include-start (puppet-in-include))
          (block-indent (puppet-block-indent))
          cur-indent)
      (cond
       (array-start
        ;; This line probably starts with an element from an array.
        ;; Indent the line to the same indentation as the first
        ;; element in that array.  That is, this...
        ;;
        ;;    exec {
        ;;      "add_puppetmaster_mongrel_startup_links":
        ;;      command => "string1",
        ;;      creates => [ "string2", "string3",
        ;;      "string4", "string5",
        ;;      "string6", "string7",
        ;;      "string3" ],
        ;;      refreshonly => true,
        ;;    }
        ;;
        ;; ...should instead look like this:
        ;;
        ;;    exec {
        ;;      "add_puppetmaster_mongrel_startup_links":
        ;;      command => "string1",
        ;;      creates => [ "string2", "string3",
        ;;                   "string4", "string5",
        ;;                   "string6", "string7",
        ;;                   "string8" ],
        ;;      refreshonly => true,
        ;;    }
        (save-excursion
          (goto-char array-start)
          (forward-char 1)
          (re-search-forward "\\S-")
          (forward-char -1)
          (setq cur-indent (current-column))))
       (include-start
        (setq cur-indent include-start))
       ((and (looking-at "^\\s-*},?\\s-*$") block-indent)
        ;; This line contains a closing brace or a closing brace followed by a
        ;; comma and we're at the inner block, so we should indent it matching
        ;; the indentation of the opening brace of the block.
        (setq cur-indent block-indent))
       (t
        ;; Otherwise, we did not start on a block-ending-only line.
        (save-excursion
          ;; Iterate backwards until we find an indentation hint
          (while not-indented
            (forward-line -1)
            (cond
             ;; Comment lines are ignored unless we're at the start of the
             ;; buffer.
             ((puppet-comment-line-p)
              (if (bobp)
                  (setq not-indented nil)))

             ;; Brace or paren on a line by itself will already be indented to
             ;; the right level, so we can cheat and stop there.
             ((looking-at "^\\s-*[\)}]\\s-*")
              (setq cur-indent (current-indentation))
              (setq not-indented nil))

             ;; Brace (possibly followed by a comma) or paren not on a line by
             ;; itself will be indented one level too much, but don't catch
             ;; cases where the block is started and closed on the same line.
             ((looking-at "^[^\n\({]*[\)}],?\\s-*$")
              (setq cur-indent (- (current-indentation) puppet-indent-level))
              (setq not-indented nil))

             ;; Indent by one level more than the start of our block.  We lose
             ;; if there is more than one block opened and closed on the same
             ;; line but it's still unbalanced; hopefully people don't do that.
             ((looking-at "^.*{[^\n}]*$")
              (setq cur-indent (+ (current-indentation) puppet-indent-level))
              (setq not-indented nil))

             ;; Indent by one level if the line ends with an open paren.
             ((looking-at "^.*\(\\s-*$")
              (setq cur-indent (+ (current-indentation) puppet-indent-level))
              (setq not-indented nil))

             ;; Semicolon ends a block for a resource when multiple resources
             ;; are defined in the same block, but try not to get the case of
             ;; a complete resource on a single line wrong.
             ((looking-at "^\\([^'\":\n]\\|\"[^\n\"]*\"\\|'[^\n']*'\\)*;\\s-*$")
              (setq cur-indent (- (current-indentation) puppet-indent-level))
              (setq not-indented nil))

             ;; Indent an extra level after : since it introduces a resource.
             ((looking-at "^.*:\\s-*$")
              (setq cur-indent (+ (current-indentation) puppet-indent-level))
              (setq not-indented nil))

             ;; Start of buffer.
             ((bobp)
              (setq not-indented nil)))))

        ;; If this line contains only a closing paren, we should lose one
        ;; level of indentation.
        (if (looking-at "^\\s-*\)\\s-*$")
            (setq cur-indent (- cur-indent puppet-indent-level)))))

      ;; We've figured out the indentation, so do it.
      (if (and cur-indent (> cur-indent 0))
          (indent-line-to cur-indent)
        (indent-line-to 0)))))


;;;; Font locking

(defvar puppet-mode-syntax-table
  (let ((table (make-syntax-table prog-mode-syntax-table)))
    (modify-syntax-entry ?\' "\"'"  table)
    (modify-syntax-entry ?\" "\"\"" table)
    (modify-syntax-entry ?#  "<"    table)
    (modify-syntax-entry ?\n ">#"   table)
    (modify-syntax-entry ?\\ "\\"   table)
    (modify-syntax-entry ?$  "'"    table)
    (modify-syntax-entry ?-  "."    table)
    (modify-syntax-entry ?\( "()"   table)
    (modify-syntax-entry ?\) ")("   table)
    (modify-syntax-entry ?\{ "(}"   table)
    (modify-syntax-entry ?\} "){"   table)
    (modify-syntax-entry ?\[ "(]"   table)
    (modify-syntax-entry ?\] ")["   table)
    table)
  "Syntax table in use in `puppet-mode' buffers.")

(eval-and-compile
  ;; Make these available during compilation, for use with `rx'

  (defconst puppet-keywords-re
    ;; See
    ;; http://docs.puppetlabs.com/puppet/latest/reference/lang_reserved.html#reserved-words
    (rx symbol-start
        (or "and" "case" "class" "default" "define" "else" "elsif" "false" "if"
            "in" "import" "inherits" "node" "or" "true" "undef" "unless")
        symbol-end)
    "Regular expression to match Puppet keywords.")

  (defconst puppet-builtin-functions-re
    ;; See http://docs.puppetlabs.com/references/latest/function.html
    (rx symbol-start
        (or "alert" "collect" "contain" "create_resources" "crit" "debug"
            "defined" "each" "emerg" "err" "extlookup" "fail" "file" "filter"
            "fqdn_rand" "generate" "hiera" "hiera_array" "hiera_hash"
            "hiera_include" "include" "info" "inline_template" "lookup" "map"
            "md5" "notice" "realize" "reduce" "regsubst" "require" "search"
            "select" "sha1" "shellquote" "slice" "split" "sprintf" "tag"
            "tagged" "template" "versioncmp" "warning")
        symbol-end)
    "Regular expression to match all builtin functions of Puppet.")

  (defconst puppet-builtin-types-re
    ;; See http://docs.puppetlabs.com/references/latest/type.html
    (rx symbol-start
        (or "augeas" "computer" "cron" "exec" "file" "filebucket"
            "group" "host" "interface" "k5login" "macauthorization"
            "mailalias" "maillist" "mcx" "mount" "nagios_command"
            "nagios_contact" "nagios_contactgroup" "nagios_host"
            "nagios_hostdependency" "nagios_hostescalation"
            "nagios_hostextinfo" "nagios_hostgroup" "nagios_service"
            "nagios_servicedependency" "nagios_serviceescalation"
            "nagios_serviceextinfo" "nagios_servicegroup"
            "nagios_timeperiod" "notify" "package" "resources" "router"
            "schedule" "scheduled_task" "selboolean" "selmodule"
            "service" "ssh_authorized_key" "sshkey" "stage" "tidy"
            "user" "vlan" "yumrepo" "zfs" "zone" "zpool")
        symbol-end)
    "Regular expression to match all builtin types of Puppet.")

  (defconst puppet-builtin-metaparameters-re
    ;; See http://docs.puppetlabs.com/references/stable/metaparameter.html
    (rx symbol-start
        (or "alias" "audit" "before" "loglevel" "noop" "notify"
            "require" "schedule" "stage" "subscribe" "tag"
            ;; Strictly speaking, this is no meta parameter, but it's so
            ;; common that it got a mention in the docs, see
            ;; http://docs.puppetlabs.com/puppet/latest/reference/lang_resources.html#ensure,
            ;; so we'll consider it as metaparameter anyway
            "ensure")
        symbol-end)
    "Regular expression to match all builtin meta parameters of Puppet.")

  (defconst puppet-resource-name-re
    (rx
     ;; Optional top-level scope
     (optional (any "a-z")
               (zero-or-more (any "a-z" "0-9" "_")))
     ;; Nested sub-scopes
     (zero-or-more "::"
                   (any "a-z")
                   (zero-or-more (any "a-z" "0-9" "_"))))
    "Regular expression to match a Puppet resource name.")

  (defconst puppet-capitalized-resource-name-re
    (rx
     ;; Optional top-level scope
     (optional (any "A-Z")
               (zero-or-more (any "a-z" "0-9" "_")))
     ;; Nested sub-scopes
     (zero-or-more "::"
                   (any "A-Z")
                   (zero-or-more (any "a-z" "0-9" "_"))))
    "Regular expression to match a capitalized Puppet resource name."))

(defvar puppet-font-lock-keywords
  `(
    ;; Keywords
    (,(rx (group (eval (list 'regexp puppet-keywords-re))))
     1 font-lock-keyword-face)
    ;; Variables
    (,(rx (group "$"
                 symbol-start
                 ;; The optional scope designation
                 (optional
                  (optional (any "a-z")
                            (zero-or-more (any "A-Z" "a-z" "0-9" "_")))
                  (zero-or-more "::"
                                (any "a-z")
                                (zero-or-more (any "A-Z" "a-z" "0-9" "_")))
                  "::")
                 ;; The final variable name
                 (one-or-more (any "A-Z" "a-z" "0-9" "_"))
                 symbol-end)) 1 font-lock-variable-name-face t)
    ;; Type declarations
    (,(rx symbol-start (or "class" "define" "node") symbol-end
          (one-or-more space)
          symbol-start
          (group (eval (list 'regexp puppet-resource-name-re)))
          symbol-end)
     1 font-lock-type-face)
    ;; Resource usage, see
    ;; http://docs.puppetlabs.com/puppet/latest/reference/lang_resources.html
    (,(rx symbol-start
          (group
           ;; Virtual and exported resources
           (repeat 0 2 "@")
           (eval (list 'regexp puppet-resource-name-re)))
          symbol-end
          (zero-or-more space) "{") 1 font-lock-type-face)
    ;; Resource defaults, see
    ;; http://docs.puppetlabs.com/puppet/latest/reference/lang_defaults.html
    (,(rx symbol-start
          (group (eval (list 'regexp puppet-capitalized-resource-name-re)))
          symbol-end
          (zero-or-more space) "{") 1 font-lock-type-face)
    ;; Resource references, see
    ;; http://docs.puppetlabs.com/puppet/latest/reference/lang_datatypes.html#resource-references
    (,(rx symbol-start
          (group (eval (list 'regexp puppet-capitalized-resource-name-re)))
          symbol-end
          (zero-or-more space) "[") 1 font-lock-type-face)
    ;; Resource collectors, see
    ;; http://docs.puppetlabs.com/puppet/latest/reference/lang_collectors.html
    (,(rx symbol-start
          (group (eval (list 'regexp puppet-capitalized-resource-name-re)))
          symbol-end
          (zero-or-more space)
          (optional "<")                ; Exported collector
          "<|") 1 font-lock-type-face)
    ;; Negation
    ("!" 0 font-lock-negation-char-face)
    ;; Builtin meta parameters
    (,(rx (group (eval (list 'regexp puppet-builtin-metaparameters-re)))
          (zero-or-more space)
          "=>") 1 font-lock-builtin-face)
     ;; Built-in functions
    (,(rx (group (eval (list 'regexp puppet-builtin-functions-re))))
     1 font-lock-builtin-face))
  "Font lock keywords for Puppet Mode.")


;;;; Alignment

(defconst puppet-mode-align-rules
  '((puppet-resource-arrow
     (regexp . "\\(\\s-*\\)=>\\(\\s-*\\)")
     (group  . (1 2))
     (modes  . '(puppet-mode))))
  "Align rules for Puppet Mode.")


;;;; Major mode definition

(defvar puppet-mode-map
  (let ((map (make-sparse-keymap)))
    ;; Apply manifests
    (define-key map (kbd "C-c C-c") #'puppet-apply)
    ;; Linting and validation
    (define-key map (kbd "C-c C-v") #'puppet-validate)
    (define-key map (kbd "C-c C-l") #'puppet-lint)
    ;; The menu bar
    (easy-menu-define puppet-menu map "Puppet Mode menu"
      `("Puppet"
        :help "Puppet-specific Features"
        ["Apply manifest" puppet-apply :help "Apply a Puppet manifest"]
        "-"
        ["Validate file syntax" puppet-validate
         :help "Validate the syntax of this file"]
        ["Lint file" puppet-lint
         :help "Check the file for semantic issues"]))
    map)
  "Key map for Puppet Mode buffers.")

;;;###autoload
(define-derived-mode puppet-mode prog-mode "Puppet" ()
  "Major mode for editing Puppet manifests.

\\{puppet-mode-map}"
  ;; Misc variables
  (setq-local require-final-newline t)
  ;; Comment setup
  (setq-local comment-start "# ")
  (setq-local comment-start-skip "#+ *")
  (setq-local comment-use-syntax t)
  (setq-local comment-end "")
  (setq-local comment-auto-fill-only-comments t)
  (setq comment-column puppet-comment-column)
  ;; Indentation
  (setq-local indent-line-function 'puppet-indent-line)
  (setq indent-tabs-mode puppet-indent-tabs-mode)
  ;; Paragaphs
  (setq-local paragraph-ignore-fill-prefix t)
  (setq-local paragraph-start "\f\\|[ \t]*$\\|#$")
  (setq-local paragraph-separate "\\([ \t\f]*\\|#\\)$")
  ;; Font locking
  (setq font-lock-defaults '((puppet-font-lock-keywords) nil nil))
  (setq-local font-lock-multiline t)
  ;; Alignment
  (setq align-mode-rules-list puppet-mode-align-rules))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.pp\\'" . puppet-mode))

(provide 'puppet-mode)

;;; puppet-mode.el ends here
