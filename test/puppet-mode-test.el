;;; puppet-mode-test.el --- Puppet Mode: Unit test suite  -*- lexical-binding: t; -*-

;; Copyright (C) 2013-2014, 2016  Sebastian Wiesner <swiesner@lunaryorn.com>
;; Copyright (C) 2013, 2014  Bozhidar Batsov <bozhidar@batsov.com>

;; Author: Sebastian Wiesner <swiesner@lunaryorn.com>
;; Maintainer: Bozhidar Batsov <bozhidar@batsov.com>
;;     Sebastian Wiesner <swiesner@lunaryorn.com>
;; URL: https://github.com/voxpupuli/puppet-mode

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

(defun puppet-test-indent (code)
  "Test indentation of Puppet code.

The code argument is a string that should contain correctly
indented Puppet code. The code is indented using indent-region
and the test succeeds if the result did not change"
  (puppet-test-with-temp-buffer code
                                (indent-region (point-min) (point-max))
                                (should (string= (buffer-string)
                                                 code))))


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
  ;; https://github.com/voxpupuli/puppet-mode/issues/36 for details
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

(ert-deftest puppet-font-lock-keywords/plan ()
  :tags '(fontification font-lock-keywords)
  (puppet-test-with-temp-buffer "plan foo::bar($foo) {"
    ;; The keyword
    (should (eq (puppet-test-face-at 1) 'font-lock-keyword-face))
    ;; The scope
    (should (eq (puppet-test-face-at 6) 'font-lock-type-face))
    ;; The scope operator
    (should (eq (puppet-test-face-at 9) 'font-lock-type-face))
    ;; The name
    (should (eq (puppet-test-face-at 11) 'font-lock-type-face))
    ;; The parenthesis
    (should-not (puppet-test-face-at 14))
    ;; The parameter
    (should (eq (puppet-test-face-at 15) 'font-lock-variable-name-face))
    (should-not (puppet-test-face-at 19))))

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

(ert-deftest puppet-align-block/skip-nested-blocks ()
  :tags '(alignment)
  (puppet-test-with-temp-buffer
      "
package { 'foo':
  ensure => latest,
  require    => Package['bar'],
  install_options =>   ['--foo', '--bar'],
  foo => {
    bar => 'qux',
    quxc => 'bar',
  }
}"
    (search-forward "'foo':")
    (puppet-align-block)
    (should (string= (buffer-string) "
package { 'foo':
  ensure          => latest,
  require         => Package['bar'],
  install_options => ['--foo', '--bar'],
  foo             => {
    bar => 'qux',
    quxc => 'bar',
  }
}"))))

(ert-deftest puppet-align-block/ignores-commented-out-lines ()
  :tags '(alignment)
  (puppet-test-with-temp-buffer
      "
package { 'foo':
  ensure  => latest,
  # require => Package['bar'],
}"
    (search-forward "'foo':")
    (puppet-align-block)
    (should (string= (buffer-string) "
package { 'foo':
  ensure => latest,
  # require => Package['bar'],
}"))))

(ert-deftest puppet-align-block/skip-previous-nested-block ()
  :tags '(alignment)
   (puppet-test-with-temp-buffer
      "
class foo {
  $x = {
    'a'=>1,
    'foo'=>{
      'apples'=>1,
    },
    'metafalica'=>1,
  }
}"
    (search-forward "'metafalica'")
    (puppet-align-block)
    (should (string= (buffer-string) "
class foo {
  $x = {
    'a'          => 1,
    'foo'        => {
      'apples'=>1,
    },
    'metafalica' => 1,
  }
}"))))

(ert-deftest puppet-align-block/point-in-string ()
  :tags '(alignment)
   (puppet-test-with-temp-buffer
      "
class foo {
  $x = {
    'a'=>1,
    'foo'=>{
      'apples'=>1,
    },
    'metafalica'=>1,
  }
}"
    (search-forward "tafalica")
    (puppet-align-block)
    (should (string= (buffer-string) "
class foo {
  $x = {
    'a'          => 1,
    'foo'        => {
      'apples'=>1,
    },
    'metafalica' => 1,
  }
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


;;;; Indentation

(ert-deftest puppet-in-array/simple ()
  (puppet-test-with-temp-buffer
      "\
[
1,
]"
    (forward-line 1)
    (should (= (puppet-in-array) 1))))

(ert-deftest puppet-in-array/nested-before ()
  (puppet-test-with-temp-buffer
      "\
[ [2,],
1,
]"
    (forward-line 1)
    (should (= (puppet-in-array) 1))))

(ert-deftest puppet-in-array/ignore-comment ()
  (puppet-test-with-temp-buffer
      "\
# [
1,
# ]"
    (forward-line 1)
    (should (not (puppet-in-array)))))

(ert-deftest puppet-in-argument-list/simple ()
  (puppet-test-with-temp-buffer
      "\
foo(
1,
)"
    (forward-line 1)
    (should (= (puppet-in-argument-list) 4))))

(ert-deftest puppet-in-argument-list/nested-before ()
  (puppet-test-with-temp-buffer
      "\
foo(foo(2),
1,
)"
    (forward-line 1)
    (should (= (puppet-in-argument-list) 4))))

(ert-deftest puppet-in-argument-list/ignore-comment ()
  (puppet-test-with-temp-buffer
      "\
# foo(
1,
# )"
    (forward-line 1)
    (should (not (puppet-in-argument-list)))))

(ert-deftest puppet-indent-line/argument-list ()
  (puppet-test-indent "
class foo {
  $foo = bar(1,2)
  $foo = bar(
    1,
    2
  )
  $foo = bar(
    1,
    2)
  $foo = bar(1,
             2
            )
  $foo = bar(1,
             2)

  foo { 'foo':
    foo => bar(1,2),
    foo => bar(
      1,
      2,
    ),
    foo => bar(
      1,
      2),
    foo => bar(1,
               2,
              ),
    foo => bar(1,
               2),
    foo => 0;
  }
}
"))

(ert-deftest puppet-indent-line/array ()
  (puppet-test-indent "
class foo {
  $foo = [
    $bar,
  ]
  $foo = [
    $bar]
  $foo = [$bar,
          $bar,
         ]
  $foo = [$bar,
          $bar]
  foo { 'foo':
    bar => [
      $bar,
      $bar,
    ],
    bar => [$bar,
            $bar,
           ],
    bar => [$bar,
            $bar],
    bar => $bar;
  }
}
"))

(ert-deftest puppet-indent-line/class ()
  (puppet-test-with-temp-buffer
      "class test (
$foo = $title,
  ) {
$bar = 'hello'
}"
    (indent-region (point-min) (point-max))
    (should (string= (buffer-string)
                     "class test (
  $foo = $title,
) {
  $bar = 'hello'
}"
))))

(ert-deftest puppet-indent-line/class-inherits ()
  (puppet-test-with-temp-buffer
      "class test (
$foo = $title,
  ) inherits ::something::someting:dark::side {
$bar = 'hello'
}"
    (indent-region (point-min) (point-max))
    (should (string= (buffer-string)
                     "class test (
  $foo = $title,
) inherits ::something::someting:dark::side {
  $bar = 'hello'
}"
))))

(ert-deftest puppet-indent-line/class-no-parameters ()
  (puppet-test-with-temp-buffer
      "class test () {
$bar = 'hello'
}"
    (indent-region (point-min) (point-max))
    (should (string= (buffer-string)
                     "class test () {
  $bar = 'hello'
}"
))))

(ert-deftest puppet-indent-line/class-no-parameters-2 ()
  (puppet-test-with-temp-buffer
      "class foobar {
class { 'test':
omg => 'omg',
lol => {
asd => 'asd',
fgh => 'fgh',
}
}
}
"
    (indent-region (point-min) (point-max))
    (should (string= (buffer-string)
                     "class foobar {
  class { 'test':
    omg => 'omg',
    lol => {
      asd => 'asd',
      fgh => 'fgh',
    }
  }
}
"
))))

(ert-deftest puppet-indent-line/class-no-parameters-inherits ()
  (puppet-test-with-temp-buffer
      "class test () inherits ::something::someting:dark::side {
$bar = 'hello'
}"
    (indent-region (point-min) (point-max))
    (should (string= (buffer-string)
                     "class test () inherits ::something::someting:dark::side {
  $bar = 'hello'
}"
))))

(ert-deftest puppet-indent-line/class-paramaters-no-inherits ()
  (puppet-test-with-temp-buffer
      "
class foo (
String $foo,
) {
}"
    (indent-region (point-min) (point-max))
    (should (string= (buffer-string)
      "
class foo (
  String $foo,
) {
}"
))))

(ert-deftest puppet-indent-line/class-paramaters-inherits ()
  (puppet-test-with-temp-buffer
      "
class foo::bar (
String $foo,
) inherits foo {
}"
    (indent-region (point-min) (point-max))
    (should (string= (buffer-string)
      "
class foo::bar (
  String $foo,
) inherits foo {
}"
))))

(ert-deftest puppet-indent-line/class-parameter-list ()
  (puppet-test-indent "
class foo::bar1 ($a, $b,
                 $c, $d,
) {
  $foo = $bar
}

class foo::bar2 ($a, $b,
                 $c, $d)
{
  $foo = $bar
}

class foo::bar3 ($a, $b,
                 $c, $d,
)
{
  $foo = $bar
}

class foo::bar4 ($a, $b)
{
  $foo = $bar
}

class foo::bar5 ($a, $b) {
  $foo = $bar
}
"))

(ert-deftest puppet-indent-line/class-parameter-list-fail ()
  :expected-result :failed
  (puppet-test-indent "
class foo::bar ($a, $b,
                $c, $d) {
  $foo = $bar
}
"))

(ert-deftest puppet-indent-line/comments-change-indentation-level ()
  (puppet-test-with-temp-buffer
      "
if $foo {
# {
# (
# :
# ;
# }
# )
#
}
"
    (indent-region (point-min) (point-max))
    (should (string= (buffer-string)
      "
if $foo {
  # {
  # (
  # :
  # ;
  # }
  # )
  #
}
"
))))

(ert-deftest puppet-indent-line/define ()
  (puppet-test-with-temp-buffer
      "
define foo::bar (
$foo = $title,
) {
$bar = 'hello'
}"
    (indent-region (point-min) (point-max))
    (should (string= (buffer-string)
                     "
define foo::bar (
  $foo = $title,
) {
  $bar = 'hello'
}"
))))

(ert-deftest puppet-indent-line/define-lonely-opening-paren ()
  (puppet-test-with-temp-buffer
      "
define foo::bar
(
$foo = $title,
) {
$bar = 'hello'
}"
    (indent-region (point-min) (point-max))
    (should (string= (buffer-string)
                     "
define foo::bar
(
  $foo = $title,
) {
  $bar = 'hello'
}"
))))

(ert-deftest puppet-indent-line/extra-indent-after-colon ()
  (puppet-test-with-temp-buffer
      "
class foo {
# no extra indent after this:
bar {
'extra indent after this':
foo => 'bar';
}
}"
    (indent-region (point-min) (point-max))
    (should (string= (buffer-string)
      "
class foo {
  # no extra indent after this:
  bar {
    'extra indent after this':
      foo => 'bar';
  }
}"
))))

(ert-deftest puppet-indent-line/if ()
  (puppet-test-with-temp-buffer
      "
class foo {
if $foo {
$foo = 'bar'
}
}
"
    (indent-region (point-min) (point-max))
    (should (string= (buffer-string)
      "
class foo {
  if $foo {
    $foo = 'bar'
  }
}
"
))))

(ert-deftest puppet-indent-line/if-elsif-else ()
  (puppet-test-with-temp-buffer
      "
class foo {
if $foo == 'foo' {
$bar = 'foo1'
}
elsif $foo == 'bar' {
$bar = 'foo2'
}
else {
$bar = 'foo3'
}
}
"
    (indent-region (point-min) (point-max))
    (should (string= (buffer-string)
      "
class foo {
  if $foo == 'foo' {
    $bar = 'foo1'
  }
  elsif $foo == 'bar' {
    $bar = 'foo2'
  }
  else {
    $bar = 'foo3'
  }
}
"
))))

(ert-deftest puppet-indent-line/if-statement-with-no-newline-after-closing-braces ()
  (puppet-test-with-temp-buffer
      "
class foo {
if $foo == 'foo' {
$bar = 'foo1'
} elsif $foo == 'bar' {
$bar = 'foo2'
} else {
$bar = 'foo3'
}
}
"
    (indent-region (point-min) (point-max))
    (should (string= (buffer-string)
      "
class foo {
  if $foo == 'foo' {
    $bar = 'foo1'
  } elsif $foo == 'bar' {
    $bar = 'foo2'
  } else {
    $bar = 'foo3'
  }
}
"
))))

(ert-deftest puppet-indent-line/nested-hash ()
  (puppet-test-with-temp-buffer
      "
class foo {
$x = {
'foo' => {
'bar' => 1,
},
'spam' => {
'eggs' => 1,
},
}
}
"
    (indent-region (point-min) (point-max))
    (should (string= (buffer-string)
                     "
class foo {
  $x = {
    'foo' => {
      'bar' => 1,
    },
    'spam' => {
      'eggs' => 1,
    },
  }
}
"
))))

(ert-deftest puppet-indent-line/nested-hash-inside-array ()
  (puppet-test-with-temp-buffer
      "
$shadow_config_settings = [
{
section => 'CROS',
setting => 'dev_server',
value   => join($dev_server, ','),
require => Package['foo'],
},
]
"
    (indent-region (point-min) (point-max))
    (should (string= (buffer-string)
                     "
$shadow_config_settings = [
  {
    section => 'CROS',
    setting => 'dev_server',
    value   => join($dev_server, ','),
    require => Package['foo'],
  },
]
"
))))

(ert-deftest puppet-indent-line/nested-hash-inside-array-inside-hash ()
  (puppet-test-with-temp-buffer
      "
class openvpn::config {
$defaultRules = [
{
'destination' => '192.168.540.162',
'netmask' => '255.255.255.255',
'protocol' => 'udp',
'ports' => '53',
},
{
'destination' => '192.168.540.163',
'netmask' => '255.255.255.255',
'protocol' => 'udp',
'ports' => '53',
},
]
}
"
    (indent-region (point-min) (point-max))
    (should (string= (buffer-string)
                     "
class openvpn::config {
  $defaultRules = [
    {
      'destination' => '192.168.540.162',
      'netmask' => '255.255.255.255',
      'protocol' => 'udp',
      'ports' => '53',
    },
    {
      'destination' => '192.168.540.163',
      'netmask' => '255.255.255.255',
      'protocol' => 'udp',
      'ports' => '53',
    },
  ]
}
"
))))


(ert-deftest puppet-indent-line/arrow-after-block ()
  (puppet-test-with-temp-buffer
   "
class foo {
file { '/tmp/testdir':
ensure => directory,
} ->
file { '/tmp/testdir/somefile1':
ensure => file,
} ~>
file { '/tmp/testdir/somefile2':
ensure => file,
}
}
"
   (indent-region (point-min) (point-max))
   (should (string= (buffer-string)
                    "
class foo {
  file { '/tmp/testdir':
    ensure => directory,
  } ->
  file { '/tmp/testdir/somefile1':
    ensure => file,
  } ~>
  file { '/tmp/testdir/somefile2':
    ensure => file,
  }
}
"))))


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

(provide 'puppet-mode-test)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; puppet-mode-test.el ends here
