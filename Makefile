CASK = cask
EMACS = emacs
EMACSFLAGS =
TESTFLAGS =

export EMACS

PKGDIR := $(shell EMACS=$(EMACS) $(CASK) package-directory)

SRCS = puppet-mode.el
OBJS = $(SRCS:.el=.elc)

.PHONY: compile test clean

compile: $(OBJS)

clean:
	rm -f $(OBJS)

test: $(PKGDIR)
	$(CASK) exec ert-runner $(TESTFLAGS)

%.elc : %.el $(PKGDIR)
	$(CASK) exec $(EMACS) -Q --batch $(EMACSFLAGS) -f batch-byte-compile $<

$(PKGDIR) : Cask
	@# this is a load bearing --verbose
	@# without it pkg-info fails to install in emacs 25.3 with the error
	@# Dependency pkg-info failed to install: Wrong type argument: stringp, nil
	@# Most likely a bug in cask.
	$(CASK) --verbose install
	touch $(PKGDIR)
