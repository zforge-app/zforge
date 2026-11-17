# Included from the vendored Format7zF directory; upstream sources are unchanged.
include makefile.gcc

# The app uses built-in codecs only. No external plugin registry or global new override.
LOCAL_FLAGS =
OBJS += $(O)/FileStreams.o
# Split output of edited and created split archives (ZF-83).
OBJS += $(O)/MultiOutStream.o

.PHONY: zforge-static
zforge-static: $(O)/libSevenZipCore.a

$(O)/libSevenZipCore.a: $(OBJS) $(MAKEFILE_LIST)
	/usr/bin/libtool -static -o $@ $(OBJS)

-include $(wildcard $(O)/*.d)
