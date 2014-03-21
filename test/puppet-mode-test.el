;;; puppet-mode-test.el --- Puppet Mode: Unit test suite  -*- lexical-binding: t; -*-

;; Copyright (C) 2013, 2014  Sebastian Wiesner <lunaryorn@gmail.com>
;; Copyright (C) 2013, 2014  Bozhidar Batsov <bozhidar@batsov.com>

;; Author: Sebastian Wiesner <lunaryorn@gmail.com>
;; Maintainer: Bozhidar Batsov <bozhidar@batsov.com>
;;     Sebastian Wiesner <lunaryorn@gmail.com>
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


;;;; Utilties

(defmacro puppet-test-with-temp-buffer (content &rest body)
  "Evaluate BODY in a temporary buffer with CONTENTS."
  (declare (debug t)
           (indent 1))
  `(with-temp-buffer
     (insert ,content)
     (goto-char (point-min))
     (puppet-mode)
     ,@body))

(defun puppet-test-face-at (pos &optional content)
  "Get the face at POS in CONTENT.

If CONTENT is not given, return the face at POS in the current
buffer."
  (if content
      (puppet-test-with-temp-buffer content
        (font-lock-fontify-buffer)
        (get-text-property pos 'face))
    (font-lock-fontify-buffer)
    (get-text-property pos 'face)))


;;;; Font locking

(ert-deftest puppet-mode-syntax-table/fontify-dq-string ()
  (should (eq (puppet-test-face-at 8 "$foo = \"bar\"") 'font-lock-string-face)))

(ert-deftest puppet-mode-syntax-table/fontify-sq-string ()
  (should (eq (puppet-test-face-at 8 "$foo = 'bar'") 'font-lock-string-face)))

(ert-deftest puppet-mode-syntax-table/fontify-line-comment ()
  (puppet-test-with-temp-buffer "# class
bar"
    (should (eq (puppet-test-face-at 1) 'font-lock-comment-delimiter-face))
    (should (eq (puppet-test-face-at 3) 'font-lock-comment-face))
    (should (eq (puppet-test-face-at 7) 'font-lock-comment-face))
    (should (eq (puppet-test-face-at 8) 'font-lock-comment-face))
    (should-not (puppet-test-face-at 9))))

(ert-deftest puppet-mode-syntax-table/fontify-c-style-comment ()
  (puppet-test-with-temp-buffer "/*
class */ bar"
    (should (eq (puppet-test-face-at 1) 'font-lock-comment-face))
    (should (eq (puppet-test-face-at 4) 'font-lock-comment-face))
    (should (eq (puppet-test-face-at 8) 'font-lock-comment-face))
    (should (eq (puppet-test-face-at 11) 'font-lock-comment-face))
    (should-not (puppet-test-face-at 13))))

(ert-deftest puppet-font-lock-keywords/regular-expression-literal ()
  (puppet-test-with-temp-buffer "$foo =~ / class $foo/ {"
    ;; The opening slash
    (should (eq (puppet-test-face-at 9) 'puppet-regular-expression-literal))
    ;; A keyword inside a regexp literal
    (should (eq (puppet-test-face-at 11) 'puppet-regular-expression-literal))
    ;; A variable inside a regexp literal
    (should (eq (puppet-test-face-at 17) 'puppet-regular-expression-literal))
    ;; The closing delimiter
    (should (eq (puppet-test-face-at 21) 'puppet-regular-expression-literal))
    ;; The subsequent brace
    (should-not (puppet-test-face-at 23))))

(ert-deftest puppet-font-lock-keywords/keyword-in-symbol ()
  (should-not (puppet-test-face-at 4 "fooclass")))

(ert-deftest puppet-font-lock-keywords/keyword-in-parameter-name ()
  (should-not (puppet-test-face-at 1 "node_foo => bar")))

(ert-deftest puppet-font-lock-keywords/keyword-as-parameter-name ()
  ;; We don't highlight parameters in any specific way, so the keyword will get
  ;; highlighted.  The reason is that keywords are keywords in selectors and
  ;; hashes, but variables in resources, and since both statements use the same
  ;; arrow-style syntax for key-value pairs, it's impossible to get highlighting
  ;; right without looking at the surrounding syntactic context, which is way
  ;; too much of an effort for too little gain.  See
  ;; https://github.com/lunaryorn/puppet-mode/issues/36 for details
  (should (eq (puppet-test-face-at 1 "unless => bar") 'font-lock-keyword-face)))

(ert-deftest puppet-font-lock-keywords/simple-variable ()
  (puppet-test-with-temp-buffer "$foo = bar"
    (should (eq (puppet-test-face-at 1) 'font-lock-variable-name-face))
    (should (eq (puppet-test-face-at 4) 'font-lock-variable-name-face))
    ;; The operator should not get highlighted
    (should-not (puppet-test-face-at 6))))

(ert-deftest puppet-font-lock-keywords/variable-with-scope ()
  (puppet-test-with-temp-buffer "$foo::bar"
    (should (eq (puppet-test-face-at 1) 'font-lock-variable-name-face))
    (should (eq (puppet-test-face-at 2) 'font-lock-variable-name-face))
    ;; Scope operator
    (should (eq (puppet-test-face-at 5) 'font-lock-variable-name-face))
    (should (eq (puppet-test-face-at 7) 'font-lock-variable-name-face))))

(ert-deftest puppet-font-lock-keywords/variable-in-top-scope ()
  (puppet-test-with-temp-buffer "$::foo"
    (should (eq (puppet-test-face-at 1) 'font-lock-variable-name-face))
    (should (eq (puppet-test-face-at 2) 'font-lock-variable-name-face))
    (should (eq (puppet-test-face-at 4) 'font-lock-variable-name-face))))

(ert-deftest puppet-font-lock-keywords/class ()
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
  (puppet-test-with-temp-buffer "node puppet.example.com {"
    (should (eq (puppet-test-face-at 1) 'font-lock-keyword-face))
    (should (eq (puppet-test-face-at 6) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 12) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 23) 'font-lock-type-face))
    (should-not (puppet-test-face-at 25))))

(ert-deftest puppet-font-lock-keywords/resource ()
  (puppet-test-with-temp-buffer "foo::bar {"
    (should (eq (puppet-test-face-at 1) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 4) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 6) 'font-lock-type-face))
    (should-not (puppet-test-face-at 10))))

(ert-deftest puppet-font-lock-keywords/resource-default ()
  (puppet-test-with-temp-buffer "Foo::Bar {"
    (should (eq (puppet-test-face-at 1) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 4) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 6) 'font-lock-type-face))
    (should-not (puppet-test-face-at 10))))

(ert-deftest puppet-font-lock-keywords/resource-default-not-capitalized ()
  (puppet-test-with-temp-buffer "Foo::bar {"
    (should-not (puppet-test-face-at 1))
    (should-not (puppet-test-face-at 4))
    (should-not (puppet-test-face-at 6))
    (should-not (puppet-test-face-at 8))))

(ert-deftest puppet-font-lock-keywords/resource-collector ()
  (puppet-test-with-temp-buffer "Foo::Bar <|"
    (should (eq (puppet-test-face-at 1) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 4) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 6) 'font-lock-type-face))
    (should-not (puppet-test-face-at 10))))

(ert-deftest puppet-font-lock-keywords/exported-resource-collector ()
  (puppet-test-with-temp-buffer "Foo::Bar <<|"
    (should (eq (puppet-test-face-at 1) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 4) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 6) 'font-lock-type-face))
    (should-not (puppet-test-face-at 10))
    (should-not (puppet-test-face-at 11))))

(ert-deftest puppet-font-lock-keywords/resource-collector-not-capitalized ()
  (puppet-test-with-temp-buffer "Foo::bar <<|"
    (should-not (puppet-test-face-at 1))
    (should-not (puppet-test-face-at 4))
    (should-not (puppet-test-face-at 6))
    (should-not (puppet-test-face-at 10))
    (should-not (puppet-test-face-at 11))))

(ert-deftest puppet-font-lock-keywords/negation ()
  (should (eq (puppet-test-face-at 1 "!$foo") 'font-lock-negation-char-face)))

(ert-deftest puppet-font-lock-keywords/builtin-metaparameter ()
  (puppet-test-with-temp-buffer "alias => foo"
    (should (eq (puppet-test-face-at 1) 'font-lock-builtin-face))
    (should-not (puppet-test-face-at 7))))

(ert-deftest puppet-font-lock-keywords/builtin-function ()
  (puppet-test-with-temp-buffer "template('foo/bar')"
    (should (eq (puppet-test-face-at 1) 'font-lock-builtin-face))
    (should-not (puppet-test-face-at 9))
    (should (eq (puppet-test-face-at 10) 'font-lock-string-face))))

(ert-deftest puppet-font-lock-keywords/builtin-function-in-parameter-name ()
  (puppet-test-with-temp-buffer "require => foo"
    (should (eq (puppet-test-face-at 1) 'font-lock-builtin-face))
    (should-not (puppet-test-face-at 10))))

(ert-deftest puppet-font-lock-keywords/type-argument-to-contain ()
  (puppet-test-with-temp-buffer "contain foo::bar"
    (should (eq (puppet-test-face-at 1) 'font-lock-builtin-face))
    (should (eq (puppet-test-face-at 7) 'font-lock-builtin-face))
    (should (eq (puppet-test-face-at 9) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 12) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 14) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 16) 'font-lock-type-face))))

(ert-deftest puppet-font-lock-keywords/string-argument-to-contain ()
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
  (puppet-test-with-temp-buffer "include foo::bar"
    (should (eq (puppet-test-face-at 1) 'font-lock-builtin-face))
    (should (eq (puppet-test-face-at 7) 'font-lock-builtin-face))
    (should (eq (puppet-test-face-at 9) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 12) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 14) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 16) 'font-lock-type-face))))

(ert-deftest puppet-font-lock-keywords/type-argument-to-require ()
  (puppet-test-with-temp-buffer "require foo::bar"
    (should (eq (puppet-test-face-at 1) 'font-lock-builtin-face))
    (should (eq (puppet-test-face-at 7) 'font-lock-builtin-face))
    (should (eq (puppet-test-face-at 9) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 12) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 14) 'font-lock-type-face))
    (should (eq (puppet-test-face-at 16) 'font-lock-type-face))))

(ert-deftest puppet-font-lock-keywords/variable-expansion-in-sq-string ()
  (puppet-test-with-temp-buffer "'${::foo::bar} yeah'"
    (should (eq (puppet-test-face-at 1) 'font-lock-string-face))
    (should (eq (puppet-test-face-at 2) 'font-lock-warning-face))
    (should (eq (puppet-test-face-at 3) 'font-lock-warning-face))
    (should (eq (puppet-test-face-at 4) 'font-lock-warning-face))
    (should (eq (puppet-test-face-at 6) 'font-lock-warning-face))
    (should (eq (puppet-test-face-at 14) 'font-lock-warning-face))
    (should (eq (puppet-test-face-at 16) 'font-lock-string-face))))

(ert-deftest puppet-font-lock-keywords/variable-expansion-in-dq-string ()
  (puppet-test-with-temp-buffer "\"${::foo::bar} yeah\""
    (should (eq (puppet-test-face-at 1) 'font-lock-string-face))
    (should (eq (puppet-test-face-at 2) 'font-lock-variable-name-face))
    (should (eq (puppet-test-face-at 3) 'font-lock-variable-name-face))
    (should (eq (puppet-test-face-at 4) 'font-lock-variable-name-face))
    (should (eq (puppet-test-face-at 6) 'font-lock-variable-name-face))
    (should (eq (puppet-test-face-at 14) 'font-lock-variable-name-face))
    (should (eq (puppet-test-face-at 16) 'font-lock-string-face))))

(ert-deftest puppet-font-lock-keywords/variable-expansion-in-comment-disabled ()
  (let ((puppet-fontify-variables-in-comments nil))
    (puppet-test-with-temp-buffer "# $foo bar"
      (should (eq (puppet-test-face-at 1) 'font-lock-comment-delimiter-face))
      (should (eq (puppet-test-face-at 3) 'font-lock-comment-face))
      (should (eq (puppet-test-face-at 6) 'font-lock-comment-face))
      (should (eq (puppet-test-face-at 8) 'font-lock-comment-face)))))

(ert-deftest puppet-font-lock-keywords/variable-expansion-in-comment-enabled ()
  (let ((puppet-fontify-variables-in-comments t))
    (puppet-test-with-temp-buffer "# $foo bar"
      (should (eq (puppet-test-face-at 1) 'font-lock-comment-delimiter-face))
      (should (eq (puppet-test-face-at 3) 'font-lock-variable-name-face))
      (should (eq (puppet-test-face-at 6) 'font-lock-variable-name-face))
      (should (eq (puppet-test-face-at 8) 'font-lock-comment-face)))))

(ert-deftest puppet-font-lock-keywords/escape-in-dq-string ()
  (puppet-test-with-temp-buffer "\"foo\\n\""
    (should (eq (puppet-test-face-at 1) 'font-lock-string-face))
    (should (eq (puppet-test-face-at 5) 'puppet-escape-sequence))
    (should (eq (puppet-test-face-at 6) 'puppet-escape-sequence))
    (should (eq (puppet-test-face-at 7) 'font-lock-string-face))))


;;;; Alignment tests

(ert-deftest puppet-align-block/one-block ()
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


;;;; Minor mode definition

(ert-deftest puppet-mode/movement-setup ()
  (puppet-test-with-temp-buffer "foo"
    (should (local-variable-p 'beginning-of-defun-function))
    (should (equal beginning-of-defun-function
                   #'puppet-beginning-of-defun-function))))

(ert-deftest puppet-mode/indentation-setup ()
  (puppet-test-with-temp-buffer "foo"
    (should (local-variable-p 'indent-line-function))
    (should (local-variable-p 'indent-tabs-mode))
    (should (eq indent-line-function 'puppet-indent-line))
    (should (eq indent-tabs-mode puppet-indent-tabs-mode))))

(ert-deftest puppet-mode/font-lock-setup ()
  (puppet-test-with-temp-buffer "foo"
    (should (local-variable-p 'font-lock-defaults))
    (should (local-variable-p 'syntax-propertize-function))
    (should (equal font-lock-defaults '((puppet-font-lock-keywords) nil nil)))
    (should (eq syntax-propertize-function
                #'puppet-syntax-propertize-function))))

(ert-deftest puppet-mode/alignment-setup ()
  (puppet-test-with-temp-buffer "foo"
    (should (local-variable-p 'align-mode-rules-list))
    (should (equal align-mode-rules-list puppet-mode-align-rules))))

(ert-deftest puppet-mode/imenu-setup ()
  (puppet-test-with-temp-buffer "foo"
    (should (local-variable-p 'imenu-create-index-function))
    (should (equal imenu-create-index-function #'puppet-imenu-create-index))))

(provide 'puppet-mode-test)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; puppet-mode-test.el ends here
