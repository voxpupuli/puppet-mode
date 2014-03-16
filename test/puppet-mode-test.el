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

(defmacro puppet-test-with-temp-buffer (contents &rest body)
  "Evaluate BODY in a temporary buffer with CONTENTS."
  (declare (debug t)
           (indent 1))
  `(with-temp-buffer
     (insert ,contents)
     (goto-char (point-min))
     (puppet-mode)
     ,@body))


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
