define todo_lib
 for lib in $$LIBS; do \
  $(ECHO) "\t[$$BASE/$$lib] $$lib (checking work to be done)"; \
  ./sbin/compilation/helper.sh -n -t lib$$LAB$$lib -d $$BASE/$$lib -N $(MAKEFLAGS) -m $(fast) -g $@  -- $(xcpp) $$ADF;\
 done
endef
define todo_precision
 if echo $(1)" "$(xcpp) | grep -q DOUBLE ; then \
  $(ECHO) "\t[$@] Compilation is in DOUBLE precison";\
  if [ ! -f  $(compdir)/config/stamps_and_lists/compilation_objects_in_DOUBLE_precision.stamp ]; then \
   if [ -f  $(compdir)/config/stamps_and_lists/compilation_objects_in_SINGLE_precision.stamp ]; then \
     $(ECHO) "\t[$@] Cleaning SINGLE precison source";\
     $(MAKE) $(MAKEFLAGS) clean what="int-libs"; \
     $(MAKE) $(MAKEFLAGS) clean what="driver"; \
     $(MAKE) $(MAKEFLAGS) clean what="ypp"; \
     $(MAKE) $(MAKEFLAGS) clean what="src"; \
   fi; \
   rm -f  $(compdir)/config/stamps_and_lists/compilation_objects_in_SINGLE_precision.stamp; \
   touch  $(compdir)/config/stamps_and_lists/compilation_objects_in_DOUBLE_precision.stamp; \
  fi; \
 else \
  $(ECHO) "\t[$@] Compilation is in SINGLE precison";\
  if [ ! -f  $(compdir)/config/stamps_and_lists/compilation_objects_in_SINGLE_precision.stamp ]; then \
   if [ -f  $(compdir)/config/stamps_and_lists/compilation_objects_in_DOUBLE_precision.stamp ]; then \
    $(ECHO) "\t[$@] Cleaning DOUBLE precison source";\
    $(MAKE) $(MAKEFLAGS) clean what="int-libs"; \
    $(MAKE) $(MAKEFLAGS) clean what="driver"; \
    $(MAKE) $(MAKEFLAGS) clean what="ypp"; \
    $(MAKE) $(MAKEFLAGS) clean what="src"; \
   fi; \
   touch  $(compdir)/config/stamps_and_lists/compilation_objects_in_SINGLE_precision.stamp; \
   rm -f  $(compdir)/config/stamps_and_lists/compilation_objects_in_DOUBLE_precision.stamp; \
 fi; \
fi
endef
define todo_driver
 $(ECHO) "\t[$$BASE] $$X2DO (checking work to be done)";\
 ./sbin/compilation/helper.sh -n -t $$X2DO -d $$BASE -N $(MAKEFLAGS) -g $@  -- $(xcpp) $$ADF
endef

