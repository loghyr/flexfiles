# Copyright (C) The IETF Trust (2014)
#

YEAR=`date +%Y`
MONTH=`date +%B`
DAY=`date +%d`
PREVVERS=01
VERS=02
BASEDOC=draft-bhalevy-nfsv4-flex-files
XML2RFC=xml2rfc

autogen/%.xml : %.x
	@mkdir -p autogen
	@rm -f $@.tmp $@
	@cat $@.tmp | sed 's/^\%//' | sed 's/</\&lt;/g'| \
	awk ' \
		BEGIN	{ print "<figure>"; print" <artwork>"; } \
			{ print $0 ; } \
		END	{ print " </artwork>"; print"</figure>" ; } ' \
	| expand > $@
	@rm -f $@.tmp

all: html txt

#
# Build the stuff needed to ensure integrity of document.
common: testx html

txt: $(BASEDOC)-$(VERS).txt

html: $(BASEDOC)-$(VERS).html

nr: $(BASEDOC)-$(VERS).nr

xml: $(BASEDOC)-$(VERS).xml

clobber:
	$(RM) $(BASEDOC)-$(VERS).txt \
		$(BASEDOC)-$(VERS).html \
		$(BASEDOC)-$(VERS).nr
	export SPECVERS := $(VERS)
	export VERS := $(VERS)

clean:
	rm -f $(AUTOGEN)
	rm -rf autogen
	rm -f $(BASEDOC)-$(VERS).xml
	rm -rf draft-$(VERS)
	rm -f draft-$(VERS).tar.gz
	rm -rf testx.d
	rm -rf draft-tmp.xml

# Parallel All
pall: 
	$(MAKE) xml
	( $(MAKE) txt ; echo .txt done ) & \
	( $(MAKE) html ; echo .html done ) & \
	wait

$(BASEDOC)-$(VERS).txt: $(BASEDOC)-$(VERS).xml
	${XML2RFC} --text  $(BASEDOC)-$(VERS).xml -o $@

$(BASEDOC)-$(VERS).html: $(BASEDOC)-$(VERS).xml
	${XML2RFC}  --html $(BASEDOC)-$(VERS).xml -o $@

$(BASEDOC)-$(VERS).nr: $(BASEDOC)-$(VERS).xml
	${XML2RFC} --nroff $(BASEDOC)-$(VERS).xml -o $@

flexfiles_front_autogen.xml: flexfiles_front.xml Makefile
	sed -e s/DAYVAR/${DAY}/g -e s/MONTHVAR/${MONTH}/g -e s/YEARVAR/${YEAR}/g < flexfiles_front.xml > flexfiles_front_autogen.xml

flexfiles_rfc_start_autogen.xml: flexfiles_rfc_start.xml Makefile
	sed -e s/VERSIONVAR/${VERS}/g < flexfiles_rfc_start.xml > flexfiles_rfc_start_autogen.xml

AUTOGEN =	\
		flexfiles_front_autogen.xml \
		flexfiles_rfc_start_autogen.xml

START_PREGEN = flexfiles_rfc_start.xml
START=	flexfiles_rfc_start_autogen.xml
END=	flexfiles_rfc_end.xml

FRONT_PREGEN = flexfiles_front.xml

IDXMLSRC_BASE = \
	flexfiles_middle_start.xml \
	flexfiles_middle_introduction.xml \
	flexfiles_middle_method.xml \
	flexfiles_middle_xdr_desc.xml \
	flexfiles_middle_devices.xml \
	flexfiles_middle_layout.xml \
	flexfiles_middle_existing.xml \
	flexfiles_middle_security.xml \
	flexfiles_middle_iana.xml \
	flexfiles_middle_end.xml \
	flexfiles_back_front.xml \
	flexfiles_back_references.xml \
	flexfiles_back_acks.xml \
	flexfiles_back_back.xml

IDCONTENTS = flexfiles_front_autogen.xml $(IDXMLSRC_BASE)

IDXMLSRC = flexfiles_front.xml $(IDXMLSRC_BASE)

draft-tmp.xml: $(START) Makefile $(END) $(IDCONTENTS)
		rm -f $@ $@.tmp
		cp $(START) $@.tmp
		chmod +w $@.tmp
		for i in $(IDCONTENTS) ; do cat $$i >> $@.tmp ; done
		cat $(END) >> $@.tmp
		mv $@.tmp $@

$(BASEDOC)-$(VERS).xml: draft-tmp.xml $(IDCONTENTS) $(AUTOGEN)
		rm -f $@
		cp draft-tmp.xml $@

genhtml: Makefile gendraft html txt draft-$(VERS).tar
	./gendraft draft-$(PREVVERS) \
		$(BASEDOC)-$(PREVVERS).txt \
		draft-$(VERS) \
		$(BASEDOC)-$(VERS).txt \
		$(BASEDOC)-$(VERS).html \
		$(BASEDOC)-dot-x-04.txt \
		$(BASEDOC)-dot-x-05.txt \
		draft-$(VERS).tar.gz

testx: 
	rm -rf testx.d
	mkdir testx.d
	( cd testx.d ; \
		rpcgen -a labelednfs.x ; \
		$(MAKE) -f make* )

spellcheck: $(IDXMLSRC)
	for f in $(IDXMLSRC); do echo "Spell Check of $$f"; spell +dictionary.txt $$f; done

AUXFILES = \
	dictionary.txt \
	gendraft \
	Makefile \
	errortbl \
	rfcdiff \
	xml2rfc_wrapper.sh \
	xml2rfc

DRAFTFILES = \
	$(BASEDOC)-$(VERS).txt \
	$(BASEDOC)-$(VERS).html \
	$(BASEDOC)-$(VERS).xml

draft-$(VERS).tar: $(IDCONTENTS) $(START_PREGEN) $(FRONT_PREGEN) $(AUXFILES) $(DRAFTFILES)
	rm -f draft-$(VERS).tar.gz
	tar -cvf draft-$(VERS).tar \
		$(START_PREGEN) \
		$(END) \
		$(FRONT_PREGEN) \
		$(IDCONTENTS) \
		$(AUXFILES) \
		$(DRAFTFILES) \
		gzip draft-$(VERS).tar
