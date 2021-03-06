#/usr/bin/make -f
#
NAME	=	vwifi
VERSION	=	2
BINDIR	=	$(DESTDIR)/usr/local/bin
MANDIR	=	$(DESTDIR)/usr/local/man/man1

EXEC	=	vwifi-server vwifi-client vwifi-spy vwifi-ctrl
#EXEC	=	vwifi-server vwifi-client vwifi-spy vwifi-ctrl vwifi-inet-monitor

SRC		=	src
OBJ		=	obj
MAN		=	man

CC		=	g++

#MODE= -O3 -s -Wall -Wextra -pedantic -DNDEBUG # //////////      RELEASE WITHOUT ASSERT
MODE= -O3 -s -Wall -Wextra -pedantic # //////////      RELEASE
#MODE= -g -Wall -Wextra -pedantic -D_DEBUG # //////////      DEBUG
#MODE= -pg # //////////      PROFILER --> view with : gprof $(NAME)

CFLAGS  +=  $(MODE)

NETLINK_FLAGS = -I/usr/include/libnl3
NETLINK_LIBS = -lnl-genl-3 -lnl-3

THREAD_LIBS = -lpthread

LIBS =

DEFS = -DVERSION=\"$(VERSION)\"

EUID	:= $(shell id -u -r)

##############################

vpath %.cc $(SRC)
vpath %.h $(SRC)

.PHONY: all clean build install man tools directories update gitversion

build : directories $(EXEC) # man


$(OBJ)/cselect.o: cselect.cc cselect.h types.h

$(OBJ)/cwirelessdevice.o: cwirelessdevice.cc cwirelessdevice.h

$(OBJ)/ccoordinate.o: ccoordinate.cc ccoordinate.h types.h

$(OBJ)/tools.o: tools.cc tools.h

$(OBJ)/cinfosocket.o: cinfosocket.cc cinfosocket.h types.h

$(OBJ)/cthread.o: cthread.cc cthread.h

$(OBJ)/csocket.o: csocket.cc csocket.h types.h config.h $(OBJ)/cdynbuffer.o

$(OBJ)/cwifi.o: cwifi.cc cwifi.h types.h $(OBJ)/csocket.o

$(OBJ)/csocketserver.o: csocketserver.cc csocketserver.h $(OBJ)/csocket.o $(OBJ)/cinfosocket.o types.h

$(OBJ)/cwifiserver.o: cwifiserver.cc cwifiserver.h $(OBJ)/csocketserver.o $(OBJ)/cinfowifi.o $(OBJ)/cwifi.o

$(OBJ)/csocketclient.o: csocketclient.cc csocketclient.h $(OBJ)/csocket.o $(OBJ)/tools.o

$(OBJ)/cinfowifi.o: cinfowifi.cc cinfowifi.h $(OBJ)/ccoordinate.o types.h

$(OBJ)/cctrlserver.o: cctrlserver.cc cctrlserver.h $(OBJ)/cwifiserver.o $(OBJ)/cselect.o types.h

$(OBJ)/cmonwirelessdevice.o: cmonwirelessdevice.cc cmonwirelessdevice.h

$(OBJ)/cwificlient.o: cwificlient.cc cwificlient.h $(OBJ)/csocketclient.o $(OBJ)/ckernelwifi.o $(OBJ)/cwifi.o

$(OBJ)/ckernelwifi.o: ckernelwifi.cc ckernelwifi.h $(OBJ)/csocket.o $(OBJ)/cselect.o $(OBJ)/cthread.o $(OBJ)/cdynbuffer.o hwsim.h types.h mac80211_hwsim.h ieee80211.h config.h


vwifi-server : vwifi-server.cc config.h $(OBJ)/csocket.o $(OBJ)/csocketserver.o $(OBJ)/cinfosocket.o $(OBJ)/cwifi.o $(OBJ)/cwifiserver.o $(OBJ)/cselect.o $(OBJ)/cinfowifi.o $(OBJ)/ccoordinate.o $(OBJ)/cctrlserver.o $(OBJ)/tools.o $(OBJ)/cdynbuffer.o
	$(CC) $(CFLAGS) $(DEFS) $(LDFLAGS) -o $@ $^ $(LIBS)

vwifi-ctrl : vwifi-ctrl.cc config.h $(OBJ)/csocket.o $(OBJ)/csocketclient.o $(OBJ)/ccoordinate.o $(OBJ)/cinfowifi.o $(OBJ)/tools.o $(OBJ)/cdynbuffer.o
	$(CC) $(CFLAGS) $(DEFS) $(LDFLAGS) -o $@ $^ $(LIBS)

vwifi-client : vwifi-client.cc $(OBJ)/cwirelessdevice.o $(OBJ)/cwirelessdevicelist.o $(OBJ)/cwifi.o $(OBJ)/cwificlient.o $(OBJ)/ckernelwifi.o $(OBJ)/cthread.o $(OBJ)/cselect.o $(OBJ)/csocket.o $(OBJ)/csocketclient.o $(OBJ)/cmonwirelessdevice.o $(OBJ)/tools.o $(OBJ)/cdynbuffer.o
	$(CC) $(CFLAGS) $(DEFS) $(LDFLAGS) -o $@ $(NETLINK_FLAGS) $^ $(LIBS) $(NETLINK_LIBS) $(THREAD_LIBS)

vwifi-spy : vwifi-spy.cc $(OBJ)/cwirelessdevice.o $(OBJ)/cwirelessdevicelist.o $(OBJ)/cwifi.o $(OBJ)/cwificlient.o $(OBJ)/ckernelwifi.o $(OBJ)/cthread.o $(OBJ)/cselect.o $(OBJ)/csocket.o $(OBJ)/csocketclient.o $(OBJ)/cmonwirelessdevice.o $(OBJ)/tools.o $(OBJ)/cdynbuffer.o
	$(CC) $(CFLAGS) $(DEFS) $(LDFLAGS) -o $@ $(NETLINK_FLAGS) $^ $(LIBS) $(NETLINK_LIBS) $(THREAD_LIBS)

vwifi-inet-monitor : vwifi-inet-monitor.cc  $(OBJ)/cwirelessdevice.o $(OBJ)/cmonwirelessdevice.o
	$(CC) $(CFLAGS) $(DEFS) $(LDFLAGS) -o $@ $(NETLINK_FLAGS) $^ $(LIBS) $(NETLINK_LIBS) $(THREAD_LIBS)


$(OBJ)/%.o: %.cc
	$(CC) $(CFLAGS) $(DEFS) $(LDFLAGS) -o $@ $(NETLINK_FLAGS) -c $<

$(MAN)/$(NAME).1.gz : $(MAN)/$(NAME).1
	gzip -c $(MAN)/$(NAME).1 > $(MAN)/$(NAME).1.gz

man : $(MAN)/$(NAME).1.gz

tools :
	chmod u+x tools/*

directories: $(OBJ)/.

$(OBJ)/.:
	mkdir -p $(OBJ)

all : clean build tools install

update :
	wget -q -N https://raw.githubusercontent.com/torvalds/linux/master/drivers/net/wireless/mac80211_hwsim.h -P $(SRC)

clean:
	-rm -f *~ $(SRC)/*~ $(MAN)/*~
	-rm -f $(EXEC) $(OBJ)/* $(MAN)/$(NAME).1.gz

gitversion: .git
	@sed -n "s/^\(VERSION.[^\-]*\)\(-.*\)\?/\1-$(shell git log --format="%H" -n 1)/gp" Makefile
	@sed -i "s/^\(VERSION.[^\-]*\)\(-.*\)\?/\1-$(shell git log --format="%H" -n 1)/g" Makefile

install : build
ifneq ($(EUID),0)
	@echo "Please run 'make install' as root user"
	@exit 1
endif
	chmod +x $(EXEC)
	# Install binaire :
	mkdir -p $(BINDIR) && cp -p $(EXEC) $(BINDIR)
