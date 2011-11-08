ifeq ($(V),)
  quiet = quiet_
  Q     = @
else
  quiet =
  Q     =
endif

echo-cmd = $(if $($(quiet)cmd_$(1)), echo "  $($(quiet)cmd_$(1))";)
cmd      = @$(echo-cmd) $(cmd_$(1))

# ll -> bc
cmd_ll_to_bc        = $(LLVM_AS) $(LLASFLAGS) -o $@ $<
quiet_cmd_ll_to_bc  = LLVM_AS $(notdir $@)
%.bc: %.ll
	$(call cmd,ll_to_bc)

# bc -> s
cmd_bc_to_s         = $(LLC) $(LLCFLAGS) -o $@ $<
quiet_cmd_bc_to_s   = LLC     $(notdir $@)
%.s: %.bc
	$(call cmd,bc_to_s)

# s -> o
cmd_s_to_o          = $(AS) $(ASFLAGS) -o $@ $<
quiet_cmd_s_to_o    = AS      $(notdir $@)
%.o: %.s
	$(call cmd,s_to_o)

# c -> o
cmd_c_to_o          = $(CC) $(CFLAGS) -o $@ $<
quiet_cmd_c_to_o    = CC      $(notdir $@)
%.o: %.c
	$(call cmd,c_to_o)

# hs -> elf
cmd_hs_to_elf       = $(GHC) -o $@ $(GHCFLAGS) -v0 $< queue.o thread.o
quiet_cmd_hs_to_elf = GHC     $(notdir $@)
%.elf: %.hs queue.o thread.o
	$(call cmd,hs_to_elf)

# linking target
cmd_ld_done         = $(LD) $(LDFLAGS) -o $@ $< queue.o thread.o
quiet_cmd_ld_done   = LD      $(notdir $@)
%.elf: %.o queue.o thread.o
	$(call cmd,ld_done)
