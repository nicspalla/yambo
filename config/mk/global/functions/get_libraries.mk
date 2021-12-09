# Download external libs #
define get_external_libraries
 mkdir -p lib/archive; \
 cd lib/archive; \
 if [ "$$LIB2DO" = "all" ] ; then \
  $(MAKE) --no-print-directory -f Makefile.loc all ; \
 else \
  $(MAKE) --no-print-directory -f Makefile.loc $$LIB2DO ; \
 fi
endef
