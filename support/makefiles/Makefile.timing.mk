.PHONY: %-timed
%-timed:
	@support/dev/makefile-timeit time-service-start $(*F)
	@make $(*F)-run
	@support/dev/makefile-timeit time-service-end $(*F)
