.PHONY: object-storage-update
object-storage-update: object-storage-update-timed

.PHONY: object-storage-update-run
object-storage-update-run: object-storage-setup

object-storage-setup:
	$(Q)rake object_store:setup
