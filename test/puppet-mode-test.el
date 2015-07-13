;;; puppet-mode-test.el --- Puppet Mode: Unit test suite  -*- lexical-binding: t; -*-

;; Copyright (C) 2013, 2014  Sebastian Wiesner <swiesner@lunaryorn.com>
;; Copyright (C) 2013, 2014  Bozhidar Batsov <bozhidar@batsov.com>

;; Author: Sebastian Wiesner <swiesner@lunaryorn.com>
;; Maintainer: Bozhidar Batsov <bozhidar@batsov.com>
;;     Sebastian Wiesner <swiesner@lunaryorn.com>
;; URL: https://github.com/lunaryorn/puppet-mode

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; The unit test suite of Puppet Mode

;;; Code:

(require 'puppet-mode)
(require 'ert)


;;;; Utilities

(defmacro puppet-test-with-temp-buffer (content &rest body)
  "Evaluate BODY in a temporary buffer with CONTENTS."
  (declare (debug t)
           (indent 1))
  `(with-temp-buffer
     (insert ,content)
     (puppet-mode)
     (font-lock-fontify-buffer)
     (goto-char (point-min))
     ,@body))

(defun puppet-test-face-at (pos &optional content)
  "Get the face at POS in CONTENT.

If CONTENT is not given, return the face at POS in the current
buffer."
  (if content
      (puppet-test-with-temp-buffer content
        (get-text-property pos 'face))
    (get-text-property pos 'face)))

(defconst puppet-test-syntax-classes
  [whitespace punctuation word symbol open-paren close-paren expression-prefix
              string-quote paired-delim escape character-quote comment-start
              comment-end inherit generic-comment generic-string]
  "Readable symbols for syntax classes.

Each symbol in this vector corresponding to the syntax code of
its index.")

(defun puppet-test-syntax-at (pos)
  "Get the syntax at POS.

Get the syntax class symbol at POS, or nil if there is no syntax a
POS."
  (let ((code (syntax-class (syntax-after pos))))
    (aref puppet-test-syntax-classes code)))


;;;; Navigation

(ert-deftest puppet-syntax-propertize-function/forward-sexp-moves-across-regexp-literals ()
  :tags '(navigation syntax-properties)
  (puppet-test-with-temp-buffer "$foo =~ / (class|node) $foo/ {"
    (search-forward "=~")               ; Point is before opening / now
    (forward-sexp)
    (should (looking-at " {"))))


;;;; Font locking

(ert-deftest puppet-mode-syntax-table/fontify-dq-string ()
  :tags '(fontification syntax-table)
  (should (eq (puppet-test-face-at 8 "$foo = \"bar\"") 'font-lock-string-face)))

(ert-deftest puppet-mode-syntax-table/fontify-sq-string ()
  :tags '(fontification syntax-table)
  (should (eq (puppet-test-face-at 8 "$foo = 'bar'") 'font-lock-string-face)))

(ert-deftest puppet-mode-syntax-table/fontify-line-comment ()
  :tags '(fontification syntax-table)
  (puppet-test-with-temp-buffer "# class
bar"
    (should (eq (puppet-test-face-at 1) 'font-lock-comment-delimiter-face))
    (should (eq (puppet-test-face-at 3) 'font-lock-comment-face))
    (should (eq (puppet-test-face-at 7) 'font-lock-comment-face))
    (should (eq (puppet-test-face-at 8) 'font-lock-comment-face))
    (should-not (puppet-test-face-at 9))))

(ert-deftest puppet-mode-syntax-table/fontify-c-style-comment ()
  :tags '(fontification syntax-table)
  (puppet-test-with-temp-buffer "/*
class */ bar"
    (should (eq (puppet-test-face-at 1) 'font-lock-comment-face))
    (should (eq (puppet-test-face-at 4) 'font-lock-comment-face))
    (should (eq (puppet-test-face-at 8) 'font-lock-comment-face))
    (should (eq (puppet-test-face-at 11) 'font-lock-comment-face))
    (should-not (puppet-test-face-at 13))))

(ert-deftest puppet-syntax-propertize-function/regular-expression-literal-match-op ()
  :tags '(syntax-table syntax-properties)
  (puppet-test-with-temp-buffer "$foo =~ / class $foo/ {"
    (should (eq (puppet-test-syntax-at 9) 'generic-string))
    (should (eq (puppet-test-syntax-at 21) 'generic-string))))

(ert-deftest puppet-syntax-propertize-function/regular-expression-literal-no-match-op ()
  :tags '(syntax-table syntax-properties)
  (puppet-test-with-temp-buffer "$foo !~ / class $foo/ {"
    (should (eq (puppet-test-syntax-at 9) 'generic-string))
    (should (eq (puppet-test-syntax-at 21) 'generic-string))))

(ert-deftest puppet-syntax-propertize-function/regular-expression-literal-node ()
  :tags '(syntax-table syntax-properties)
  (puppet-test-with-temp-buffer "node / class $foo/ {"
    (should (eq (puppet-test-syntax-at 6) 'generic-string))
    (should (eq (puppet-test-syntax-at 6) 'generic-string))))

(ert-deftest puppet-syntax-propertize-function/regular-expression-literal-selector ()
  :tags '(syntax-table syntax-properties)
  (puppet-test-with-temp-buffer "/ class $foo/=>"
    (should (eq (puppet-test-syntax-at 1) 'generic-string))
    (should (eq (puppet-test-syntax-at 13) 'generic-string))))

(ert-deftest puppet-syntax-propertize-function/regular-expression-case ()
  :tags '(syntax-table syntax-properties)
  (puppet-test-with-temp-buffer "/ class $foo/:"
    (should (eq (puppet-test-syntax-at 1) 'generic-string))
    (should (eq (puppet-test-syntax-at 13) 'generic-string))))

(ert-deftest puppet-syntax-propertize-function/invalid-regular-expression ()
  :tags '(syntax-table syntax-properties)
  (puppet-test-with-temp-buffer "$foo = / class $foo/"
    (should (eq (puppet-test-syntax-at 8) 'punctuation))
    (should (eq (puppet-test-syntax-at 20) 'punctuation))))

(ert-deftest puppet-font-lock-keywords/regular-expression-literal-match-op ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "$foo =~ / class $foo/ {"
    (should (eq (puppet-test-face-at 9) 'puppet-regular-expression-literal))
    (should (eq (puppet-test-face-at 11) 'puppet-regular-expression-literal))
    (should (eq (puppet-test-face-at 17) 'puppet-regular-expression-literal))
    (should (eq (puppet-test-face-at 21) 'puppet-regular-expression-literal))
    (should-not (puppet-test-face-at 23))))

(ert-deftest puppet-font-lock-keywords/regular-expression-literal-no-match-op ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "$foo !~ / class $foo/ {"
    (should (eq (puppet-test-face-at 9) 'puppet-regular-expression-literal))
    (should (eq (puppet-test-face-at 11) 'puppet-regular-expression-literal))
    (should (eq (puppet-test-face-at 17) 'puppet-regular-expression-literal))
    (should (eq (puppet-test-face-at 21) 'puppet-regular-expression-literal))
    (should-not (puppet-test-face-at 23))))

(ert-deftest puppet-font-lock-keywords/regular-expression-literal-node ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "node / class $foo/ {"
    (should (eq (puppet-test-face-at 6) 'puppet-regular-expression-literal))
    (should (eq (puppet-test-face-at 8) 'puppet-regular-expression-literal))
    (should (eq (puppet-test-face-at 14) 'puppet-regular-expression-literal))
    (should (eq (puppet-test-face-at 18) 'puppet-regular-expression-literal))
    (should-not (puppet-test-face-at 20))))

(ert-deftest puppet-font-lock-keywords/regular-expression-literal-selector ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "/ class $foo/=>"
    (should (eq (puppet-test-face-at 1) 'puppet-regular-expression-literal))
    (should (eq (puppet-test-face-at 3) 'puppet-regular-expression-literal))
    (should (eq (puppet-test-face-at 9) 'puppet-regular-expression-literal))
    (should (eq (puppet-test-face-at 13) 'puppet-regular-expression-literal))
    (should-not (puppet-test-face-at 14))))

(ert-deftest puppet-font-lock-keywords/regular-expression-case ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "/ class $foo/:"
    (should (eq (puppet-test-face-at 1) 'puppet-regular-expression-literal))
    (should (eq (puppet-test-face-at 3) 'puppet-regular-expression-literal))
    (should (eq (puppet-test-face-at 9) 'puppet-regular-expression-literal))
    (should (eq (puppet-test-face-at 13) 'puppet-regular-expression-literal))
    (should-not (puppet-test-face-at 14))))

(ert-deftest puppet-font-lock-keywords/invalid-regular-expression ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "$foo = / class $foo/"
    (should-not (puppet-test-face-at 8))
    (should (eq (puppet-test-face-at 10) 'font-lock-keyword-face))
    (should (eq (puppet-test-face-at 16) 'font-lock-variable-name-face))
    (should-not (puppet-test-face-at 20))))

(ert-deftest puppet-font-lock-keywords/keyword-in-symbol ()
  :tags '(fontification font-lock-keywords)
  (should-not (puppet-test-face-at 4 "fooclass")))

(ert-deftest puppet-font-lock-keywords/keyword-in-parameter-name ()
  (should-not (puppet-test-face-at 1 "node_foo => bar")))

(ert-deftest puppet-font-lock-keywords/keyword-as-parameter-name ()
  :tags '(fontification font-lock-keywords)
  ;; We don't highlight parameters in any specific way, so the keyword will get
  ;; highlighted.  The reason is that keywords are keywords in selectors and
  ;; hashes, but variables in resources, and since both statements use the same
  ;; arrow-style syntax for key-value pairs, it's impossible to get highlighting
  ;; right without looking at the surrounding syntactic context, which is way
  ;; too much of an effort for too little gain.  See
  ;; https://github.com/lunaryorn/puppet-mode/issues/36 for details
  (should (eq (puppet-test-face-at 1 "unless => bar") 'font-lock-keyword-face)))

(ert-deftest puppet-font-lock-keywords/simple-variable ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "$foo = bar"
    (should (eq (puppet-test-face-at 1) 'font-lock-variable-name-face))
    (should (eq (puppet-test-face-at 4) 'font-lock-variable-name-face))
    ;; The operator should not get highlighted
    (should-not (puppet-test-face-at 6))))

(ert-deftest puppet-font-lock-keywords/simple-variable-no-space ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "$foo=bar"
    (should (eq (puppet-test-face-at 1) 'font-lock-variable-name-face))
    (should (eq (puppet-test-face-at 4) 'font-lock-variable-name-face))
    ;; The operator should not get highlighted
    (should-not (puppet-test-face-at 5))))

(ert-deftest puppet-font-lock-keywords/variable-with-scope ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "$foo::bar"
    (should (eq (puppet-test-face-at 1) 'font-lock-variable-name-face))
    (should (eq (puppet-test-face-at 2) 'font-lock-variable-name-face))
    ;; Scope operator
    (should (eq (puppet-test-face-at 5) 'font-lock-variable-name-face))
    (should (eq (puppet-test-face-at 7) 'font-lock-variable-name-face))))

(ert-deftest puppet-font-lock-keywords/variable-in-top-scope ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "$::foo"
    (should (eq (puppet-test-face-at 1) 'font-lock-variable-name-face))
    (should (eq (puppet-test-face-at 2) 'font-lock-variable-name-face))
    (should (eq (puppet-test-face-at 4) 'font-lock-variable-name-face))))

(ert-deftest puppet-font-lock-keywords/variable-before-colon ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "package { $::foo:"
    (should (eq (puppet-test-face-at 11) 'font-lock-variable-name-face))
    (should (eq (puppet-test-face-at 12) 'font-lock-variable-name-face))
    (should (eq (puppet-test-face-at 14) 'font-lock-variable-name-face))
    (should (eq (puppet-test-face-at 16) 'font-lock-variable-name-face))
    (should-not (puppet-test-face-at 17))))

(ert-deftest puppet-font-lock-keywords/class ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "class foo::bar
{"
    ;; The keyword
    (should (eq (puppet-test-face-at 1) 'font-lock-keyword-face))
    ;; The scope
    (should (eq (puppet-test-face-at 7) 'font-lock-type-face))
    ;; The scope operator
    (should (eq (puppet-test-face-at 10) 'font-lock-type-face))
    ;; The name
    (should (eq (puppet-test-face-at 12) 'font-lock-type-face))
    ;; The braces
    (should-not (puppet-test-face-at 16))))

(ert-deftest puppet-font-lock-keywords/define ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "define foo::bar($foo) {"
    ;; The keyword
    (should (eq (puppet-test-face-at 1) 'font-lock-keyword-face))
    ;; The scope
    (should (eq (puppet-test-face-at 8) 'font-lock-type-face))
    ;; The scope operator
    (should (eq (puppet-test-face-at 11) 'font-lock-type-face))
    ;; The name
    (should (eq (puppet-test-face-at 13) 'font-lock-type-face))
    ;; The parenthesis
    (should-not (puppet-test-face-at 16))
    ;; The parameter
    (should (eq (puppet-test-face-at 17) 'font-lock-variable-name-face))
    (should-not (puppet-test-face-at 21))))

(ert-deftest puppet-font-lock-keywords/node ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "node puppet.example.com {"
    (should (eq (puppet-test-face-at 1) 'font-lock-keyword-face))
    (should (eq (puppet-test-face-at 6) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 12) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 23) 'font-lock-type-face))
    (should-not (puppet-test-face-at 25))))

(ert-deftest puppet-font-lock-keywords/resource ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "foo::bar {"
    (should (eq (puppet-test-face-at 1) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 4) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 6) 'font-lock-type-face))
    (should-not (puppet-test-face-at 10))))

(ert-deftest puppet-font-lock-keywords/resource-default ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "Foo::Bar {"
    (should (eq (puppet-test-face-at 1) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 4) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 6) 'font-lock-type-face))
    (should-not (puppet-test-face-at 10))))

(ert-deftest puppet-font-lock-keywords/resource-default-not-capitalized ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "Foo::bar {"
    (should-not (puppet-test-face-at 1))
    (should-not (puppet-test-face-at 4))
    (should-not (puppet-test-face-at 6))
    (should-not (puppet-test-face-at 8))))

(ert-deftest puppet-font-lock-keywords/resource-collector ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "Foo::Bar <|"
    (should (eq (puppet-test-face-at 1) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 4) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 6) 'font-lock-type-face))
    (should-not (puppet-test-face-at 10))))

(ert-deftest puppet-font-lock-keywords/exported-resource-collector ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "Foo::Bar <<|"
    (should (eq (puppet-test-face-at 1) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 4) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 6) 'font-lock-type-face))
    (should-not (puppet-test-face-at 10))
    (should-not (puppet-test-face-at 11))))

(ert-deftest puppet-font-lock-keywords/resource-collector-not-capitalized ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "Foo::bar <<|"
    (should-not (puppet-test-face-at 1))
    (should-not (puppet-test-face-at 4))
    (should-not (puppet-test-face-at 6))
    (should-not (puppet-test-face-at 10))
    (should-not (puppet-test-face-at 11))))

(ert-deftest puppet-font-lock-keywords/negation ()
  :tags '(fontification font-lock-keywords)
  (should (eq (puppet-test-face-at 1 "!$foo") 'font-lock-negation-char-face)))

(ert-deftest puppet-font-lock-keywords/builtin-metaparameter ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "alias => foo"
    (should (eq (puppet-test-face-at 1) 'font-lock-builtin-face))
    (should-not (puppet-test-face-at 7))))

(ert-deftest puppet-font-lock-keywords/builtin-metaparameter-no-space ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "alias=>foo"
    (should (eq (puppet-test-face-at 1) 'font-lock-builtin-face))
    (should-not (puppet-test-face-at 6))))

(ert-deftest puppet-font-lock-keywords/builtin-function ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "template('foo/bar')"
    (should (eq (puppet-test-face-at 1) 'font-lock-builtin-face))
    (should-not (puppet-test-face-at 9))
    (should (eq (puppet-test-face-at 10) 'font-lock-string-face))))

(ert-deftest puppet-font-lock-keywords/builtin-function-in-parameter-name ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "require => foo"
    (should (eq (puppet-test-face-at 1) 'font-lock-builtin-face))
    (should-not (puppet-test-face-at 10))))

(ert-deftest puppet-font-lock-keywords/type-argument-to-contain ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "contain foo::bar"
    (should (eq (puppet-test-face-at 1) 'font-lock-builtin-face))
    (should (eq (puppet-test-face-at 7) 'font-lock-builtin-face))
    (should (eq (puppet-test-face-at 9) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 12) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 14) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 16) 'font-lock-type-face))))

(ert-deftest puppet-font-lock-keywords/string-argument-to-contain ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "contain 'foo::bar'"
    (should (eq (puppet-test-face-at 1) 'font-lock-builtin-face))
    (should (eq (puppet-test-face-at 7) 'font-lock-builtin-face))
    (should (eq (puppet-test-face-at 9) 'font-lock-string-face))
    (should (eq (puppet-test-face-at 10) 'font-lock-string-face))
    (should (eq (puppet-test-face-at 13) 'font-lock-string-face))
    (should (eq (puppet-test-face-at 15) 'font-lock-string-face))
    (should (eq (puppet-test-face-at 17) 'font-lock-string-face))
    (should (eq (puppet-test-face-at 18) 'font-lock-string-face))))

(ert-deftest puppet-font-lock-keywords/type-argument-to-include ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "include foo::bar"
    (should (eq (puppet-test-face-at 1) 'font-lock-builtin-face))
    (should (eq (puppet-test-face-at 7) 'font-lock-builtin-face))
    (should (eq (puppet-test-face-at 9) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 12) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 14) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 16) 'font-lock-type-face))))

(ert-deftest puppet-font-lock-keywords/type-argument-to-require ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "require foo::bar"
    (should (eq (puppet-test-face-at 1) 'font-lock-builtin-face))
    (should (eq (puppet-test-face-at 7) 'font-lock-builtin-face))
    (should (eq (puppet-test-face-at 9) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 12) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 14) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 16) 'font-lock-type-face))))

(ert-deftest puppet-font-lock-keywords/variable-expansion-in-sq-string ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "'${::foo::bar} yeah'"
    (should (eq (puppet-test-face-at 1) 'font-lock-string-face))
    (should (eq (puppet-test-face-at 2) 'font-lock-warning-face))
    (should (eq (puppet-test-face-at 3) 'font-lock-warning-face))
    (should (eq (puppet-test-face-at 4) 'font-lock-warning-face))
    (should (eq (puppet-test-face-at 6) 'font-lock-warning-face))
    (should (eq (puppet-test-face-at 14) 'font-lock-warning-face))
    (should (eq (puppet-test-face-at 16) 'font-lock-string-face))))

(ert-deftest puppet-font-lock-keywords/variable-expansion-in-dq-string ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "\"${::foo::bar} yeah\""
    (should (eq (puppet-test-face-at 1) 'font-lock-string-face))
    (should (eq (puppet-test-face-at 2) 'font-lock-variable-name-face))
    (should (eq (puppet-test-face-at 3) 'font-lock-variable-name-face))
    (should (eq (puppet-test-face-at 4) 'font-lock-variable-name-face))
    (should (eq (puppet-test-face-at 6) 'font-lock-variable-name-face))
    (should (eq (puppet-test-face-at 14) 'font-lock-variable-name-face))
    (should (eq (puppet-test-face-at 16) 'font-lock-string-face))))

(ert-deftest puppet-font-lock-keywords/variable-expansion-in-comment-disabled ()
  :tags '(fontification font-lock-keywords)
  (let ((puppet-fontify-variables-in-comments nil))
    (puppet-test-with-temp-buffer "# $foo bar"
      (should (eq (puppet-test-face-at 1) 'font-lock-comment-delimiter-face))
      (should (eq (puppet-test-face-at 3) 'font-lock-comment-face))
      (should (eq (puppet-test-face-at 6) 'font-lock-comment-face))
      (should (eq (puppet-test-face-at 8) 'font-lock-comment-face)))))

(ert-deftest puppet-font-lock-keywords/variable-expansion-in-comment-enabled ()
  :tags '(fontification font-lock-keywords)
  (let ((puppet-fontify-variables-in-comments t))
    (puppet-test-with-temp-buffer "# $foo bar"
      (should (eq (puppet-test-face-at 1) 'font-lock-comment-delimiter-face))
      (should (eq (puppet-test-face-at 3) 'font-lock-variable-name-face))
      (should (eq (puppet-test-face-at 6) 'font-lock-variable-name-face))
      (should (eq (puppet-test-face-at 8) 'font-lock-comment-face)))))

(ert-deftest puppet-font-lock-keywords/escape-in-dq-string ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "\"foo\\n\""
    (should (eq (puppet-test-face-at 1) 'font-lock-string-face))
    (should (eq (puppet-test-face-at 5) 'puppet-escape-sequence))
    (should (eq (puppet-test-face-at 6) 'puppet-escape-sequence))
    (should (eq (puppet-test-face-at 7) 'font-lock-string-face))))


;;;; Alignment tests

(ert-deftest puppet-align-block/one-block ()
  :tags '(alignment)
  (puppet-test-with-temp-buffer
      "
package { 'foo':
  ensure => latest,
  require    => Package['bar'],
  install_options =>   ['--foo', '--bar']
}"
    (search-forward "'foo':")
    (puppet-align-block)
    (should (string= (buffer-string) "
package { 'foo':
  ensure          => latest,
  require         => Package['bar'],
  install_options => ['--foo', '--bar']
}"))))

(ert-deftest puppet-align-block/stays-within-one-block ()
  :tags '(alignment)
  (puppet-test-with-temp-buffer
      "
package { 'foo':
  ensure => latest,
  require    => Package['bar'],
  install_options =>   ['--foo', '--bar']
}
package { 'bar':
  ensure    => latest,
  install_options => [],
}"
    (search-forward "'foo':")
    (puppet-align-block)
    (should (string= (buffer-string) "
package { 'foo':
  ensure          => latest,
  require         => Package['bar'],
  install_options => ['--foo', '--bar']
}
package { 'bar':
  ensure    => latest,
  install_options => [],
}"))))


;;;; Imenu

(ert-deftest puppet-imenu-create-index/class-with-variable ()
  :tags '(imenu)
  (puppet-test-with-temp-buffer
      "class hello::world {
  $foo = 'hello'
}"
    (should (equal (puppet-imenu-create-index)
                   '(("Classes" . (("hello::world" . 7)))
                     ("Variables" . (("$foo" . 24))))))))

(ert-deftest puppet-imenu-create-index/define-with-argument ()
  (puppet-test-with-temp-buffer
      "define hello::world($foo = $title) {
  $bar = 'hello'
}"
    (should (equal (puppet-imenu-create-index)
                   '(("Definitions" . (("hello::world" . 8)))
                     ("Variables" . (("$foo" . 21)
                                     ("$bar" . 40))))))))

(ert-deftest puppet-imenu-create-index/node-with-resources ()
  :tags '(imenu)
  (puppet-test-with-temp-buffer
      "node hello-world.example.com {
  Package {
    ensure => latest
  }

  package { $bar: }

  package { 'foo':
    require => Package[$bar]
  }
}"
    (should (equal (puppet-imenu-create-index)
                   '(("Nodes" ("hello-world.example.com" . 6))
                     ("Defaults" ("Package" . 34))
                     ("package $bar" . 72)
                     ("package 'foo'" . 93))))))


;;;; Major mode definition

(ert-deftest puppet-mode/movement-setup ()
  :tags '(major-mode)
  (puppet-test-with-temp-buffer "foo"
    (should (local-variable-p 'beginning-of-defun-function))
    (should (equal beginning-of-defun-function
                   #'puppet-beginning-of-defun-function))))

(ert-deftest puppet-mode/indentation-setup ()
  :tags '(major-mode)
  (puppet-test-with-temp-buffer "foo"
    (should (local-variable-p 'indent-line-function))
    (should (local-variable-p 'indent-tabs-mode))
    (should (eq indent-line-function 'puppet-indent-line))
    (should (eq indent-tabs-mode puppet-indent-tabs-mode))))

(ert-deftest puppet-mode/font-lock-setup ()
  :tags '(major-mode)
  (puppet-test-with-temp-buffer "foo"
    (should (local-variable-p 'font-lock-defaults))
    (should (local-variable-p 'syntax-propertize-function))
    (should (equal font-lock-defaults '((puppet-font-lock-keywords) nil nil)))
    (should (eq syntax-propertize-function
                #'puppet-syntax-propertize-function))))

(ert-deftest puppet-mode/alignment-setup ()
  :tags '(major-mode)
  (puppet-test-with-temp-buffer "foo"
    (should (local-variable-p 'align-mode-rules-list))
    (should (equal align-mode-rules-list puppet-mode-align-rules))))

(ert-deftest puppet-mode/imenu-setup ()
  :tags '(major-mode)
  (puppet-test-with-temp-buffer "foo"
    (should (local-variable-p 'imenu-create-index-function))
    (should (equal imenu-create-index-function #'puppet-imenu-create-index))))


;;;; Indentation

(defmacro flycheck-ert-with-temp-buffer (&rest body)
  "Eval BODY within a temporary buffer.
Like `with-temp-buffer', but resets the modification state of the
temporary buffer to make sure that it is properly killed even if
it has a backing file and is modified."
  (declare (indent 0))
  `(with-temp-buffer
     (unwind-protect
         ,(macroexp-progn body)
       ;; Reset modification state of the buffer, and unlink it from its backing
       ;; file, if any, because Emacs refuses to kill modified buffers with
       ;; backing files, even if they are temporary.
       (set-buffer-modified-p nil)
       (set-visited-file-name nil 'no-query))))

(defmacro flycheck-ert-with-file-buffer (file-name &rest body)
  "Create a buffer from FILE-NAME and eval BODY.
BODY is evaluated with `current-buffer' being a buffer with the
contents FILE-NAME."
  (declare (indent 1))
  `(let ((file-name ,file-name))
     (unless (file-exists-p file-name)
       (error "%s does not exist" file-name))
     (flycheck-ert-with-temp-buffer
       (insert-file-contents file-name 'visit)
       (set-visited-file-name file-name 'no-query)
       (cd (file-name-directory file-name))
       ;; Mark the buffer as not modified, because we just loaded the file up to
       ;; now.
       (set-buffer-modified-p nil)
       ,@body)))

(defmacro puppet-def-indent-test (filename &rest rest)
  (let ((testname (intern (format "puppet-mode/%s"
                                  (file-name-base filename))))
        (failname (format "%s-failed" filename)))
    `(ert-deftest ,testname ()
       :tags '(indentation)
       ,@rest
       (flycheck-ert-with-file-buffer
           (expand-file-name ,filename "test")
         (puppet-mode)
         (shut-up
          (indent-region (point-min) (point-max)))
         (when (buffer-modified-p)
           ;; showing a diff here would be nice
           (shut-up
            (write-region (point-min) (point-max) ,failname))
           (ert-fail ,filename))
         ))))

;; (dolist (name (directory-files "test" nil "indent.*\\.pp\\'"))
;;   (puppet-def-indent-test name))

(puppet-def-indent-test "indent-case.pp")
(puppet-def-indent-test "indent-define.pp")
(puppet-def-indent-test "indent-if.pp")
(puppet-def-indent-test "indent-node.pp")
(puppet-def-indent-test "indent-resource.pp")
;; select examples from https://docs.puppetlabs.com/guides/style_guide.html
(puppet-def-indent-test "indent-style-guide1.pp")
(puppet-def-indent-test "indent-style-guide2.pp")
(puppet-def-indent-test "indent-style-guide3.pp")
(puppet-def-indent-test "indent-style-guide4.pp")
(puppet-def-indent-test "indent-style-guide5.pp")
(puppet-def-indent-test "indent-style-guide6.pp")
;; https://projects.puppetlabs.com/issues/5403
(puppet-def-indent-test "indent-puppetlabs5403-1.pp")
(puppet-def-indent-test "indent-puppetlabs5403-2.pp")
;; https://github.com/relud/puppet-lint-strict_indent-check/blob/master/spec/fixtures/pass/1.pp
(puppet-def-indent-test "indent-puppet-lint-strict-1.pp")

(provide 'puppet-mode-test)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; puppet-mode-test.el ends here
