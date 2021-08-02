PROGNAME      := akms

prefix        := /usr/local
sbindir       := $(prefix)/sbin
libexecdir    := $(prefix)/libexec
localstatedir := /var
sysconfdir    := /etc

STATE_DIR     := $(localstatedir)/lib/$(PROGNAME)

INSTALL       := install
GIT           := git
SED           := sed

MAKEFILE_PATH  = $(lastword $(MAKEFILE_LIST))


#: Print list of targets.
help:
	@printf '%s\n\n' 'List of targets:'
	@$(SED) -En '/^#:.*/{ N; s/^#: (.*)\n([A-Za-z0-9_-]+).*/\2 \1/p }' $(MAKEFILE_PATH) \
		| while read label desc; do printf '%-15s %s\n' "$$label" "$$desc"; done

#: Install into $DESTDIR.
install:
	$(INSTALL) -D -m755 akms "$(DESTDIR)$(sbindir)/$(PROGNAME)"
	$(SED) -i \
		-e "s|/usr/libexec/akms|$(libexecdir)/$(PROGNAME)|" \
		-e "s|/var/lib/akms|$(STATE_DIR)|" \
		-e "s|/etc/akms\.conf|$(sysconfdir)/$(PROGNAME).conf|" \
		"$(DESTDIR)$(sbindir)/$(PROGNAME)"
	$(INSTALL) -D -m755 akms-build "$(DESTDIR)$(libexecdir)/$(PROGNAME)/akms-build"
	$(INSTALL) -D -m644 akms.conf "$(DESTDIR)$(sysconfdir)/$(PROGNAME).conf"
	$(INSTALL) -d -m755 "$(DESTDIR)$(STATE_DIR)"

#: Uninstall from $DESTDIR.
uninstall:
	rm -f "$(DESTDIR)$(sbindir)/$(PROGNAME)"
	rm -Rf "$(DESTDIR)$(libexecdir)/$(PROGNAME)"
	rm -f "$(DESTDIR)$(sysconfdir)/$(PROGNAME).conf"
	rmdir "$(DESTDIR)$(STATE_DIR)" || true

#: Update version in the script and README.adoc to $VERSION.
bump-version:
	test -n "$(VERSION)"  # $$VERSION
	$(SED) -E -i "s/^(readonly VERSION)=.*/\1='$(VERSION)'/" $(PROGNAME)
	$(SED) -E -i "s/^(:version:).*/\1 $(VERSION)/" README.adoc

#: Bump version to $VERSION, create release commit and tag.
release: .check-git-clean | bump-version
	test -n "$(VERSION)"  # $$VERSION
	$(GIT) add .
	$(GIT) commit -m "Release version $(VERSION)"
	$(GIT) tag -s v$(VERSION) -m v$(VERSION)


.check-git-clean:
	@test -z "$(shell $(GIT) status --porcelain)" \
		|| { echo 'You have uncommitted changes!' >&2; exit 1; }

.PHONY: help install uninstall bump-version release .check-git-clean
