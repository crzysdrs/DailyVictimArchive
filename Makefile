#
#Feather can be acquired at:
#http://www.fmwconcepts.com/imagemagick/feather/index.php
export GS_OUT=out
export GS_TMP=tmp

FEATHER_SIZE=2
HOST="blockade"
STAGE="/var/www/dev_dv/"
LIVE="/var/www/dv"

MIRROR=mirror
GS_IMG=img
HISTORY_DIR=history/

include ids.mk

.PHONY : all clean graph stage live depends vote_data
.SECONDARY :
.SUFFIXES :

ARTICLES := $(addprefix $(GS_TMP)/, $(addsuffix .article,$(IDS)))
VOTES    := $(addprefix $(GS_TMP)/, $(addsuffix .vote,$(IDS)))
DAGS     := $(addprefix $(GS_OUT)/dags/, $(addsuffix .png,$(IDS)))
#DAGS     += $(GS_OUT)/dags/all.png

VOTE_BREAKDOWN := $(addprefix $(GS_OUT)/chart/, $(addsuffix .png,$(IDS)))
VOTE_HISTORY := $(addprefix $(GS_OUT)/chart/, $(addsuffix _history.png,$(IDS)))

ALPHA_DATA := $(addprefix alpha_data, $(addsuffix .alpha,$(IDS)))

ALPHA_IDS := $(IDS)
ALPHA_IDS += fargo
ALPHA_IDS += hotsoup
ALPHA_IDS += gabe

ALPHAS        := $(addprefix $(GS_TMP)/alpha/, $(addsuffix .alpha.png,$(ALPHA_IDS)))
SAMPLES       := $(addprefix $(GS_TMP)/alpha/, $(addsuffix .sample,$(ALPHA_IDS)))
ALPHA_SHAPES  := $(addprefix $(GS_TMP)/alpha/, $(addsuffix .alpha_shape,$(ALPHA_IDS)))


all : $(GS_OUT)/dv.db $(GS_OUT)/tiles/reunion graph $(DAGS) vote_data
	@echo "All"

gamespy.tar.gz : 
	git annex init
	git annex get .

archive.touch : gamespy.tar.gz
	tar xvf gamespy.tar.gz
	touch archive.touch

history.d : archive.touch
	$(eval HISTORY   := $(shell ls $(HISTORY_DIR)/*.vote.*.html))
	$(eval HISTORYM  := $(shell ls $(MIRROR)/*.vote.html))
	$(eval HISTORYA  := $(shell ls archive.gamespy.com/comics/DailyVictim/vote.asp_id_*_dontvote_true))
	$(eval RULES = $(foreach ID, $(IDS), \
		'$$$$(GS_TMP)/$(ID).vote : ./vote.pl $(filter $(HISTORY_DIR)/$(ID).%,$(HISTORY)) $(filter mirror/$(ID).vote.html,$(HISTORYM)) $(filter %_$(ID)_dontvote_true,$(HISTORYA)) | $$$$(GS_TMP) \n\t./vote.pl $$$$@ $(ID) $(filter $(HISTORY_DIR)/$(ID).%,$(HISTORY)) $(filter %_$(ID)_dontvote_true,$(HISTORYA)) $(filter $(MIRROR)/$(ID).vote.html,$(HISTORYM))\n'))
	@echo $(RULES) > history.d

archive.gamespy.com $(HISTORY_DIR) $(MIRROR) $(GS_IMG): archive.touch

clean:
	rm -rf "$(GS_TMP)" || true
	rm -rf "$(GS_OUT)" || true
	rm history.d
	find alpha_data -size 0 -exec rm {} \;

fullclean: clean
	rm -rf archive.gamespy.com || true
	rm -rf $(MIRROR) $(GS_IMG) $(HISTORY_DIR) || true
	rm archive.touch
	git annex drop .

vote_data: $(VOTE_HISTORY) $(VOTE_BREAKDOWN)
	@echo "Votes"

$(GS_OUT)/chart/%.png $(GS_OUT)/chart/%_history.png : $(GS_TMP)/%.vote ./plot.pl | $(GS_OUT)/chart
	./plot.pl $(GS_OUT)/chart/$*.png $(GS_OUT)/chart/$*_history.png $* $^

-include history.d

depends : 
	apt-get install gnuplot graphviz \
		libimage-size-perl imagemagick \
		libdbd-sqlite3-perl sqlite3 tidy \
		perlmagick libcode-tidyall-perl \
		php-codesniffer \
		libfile-slurp-unicode-perl \
		libencode-perl \
		libcgal-dev \
		libmoosex-getopt-perl \
		git-annex

alpha_data/%.alpha : 
	touch $@

all_votes : $(VOTES)
	echo "Votes"

$(GS_OUT) : 
	mkdir $(GS_OUT)

$(GS_OUT)/dags : | $(GS_OUT)
	mkdir $(GS_OUT)/dags

$(GS_OUT)/chart : | $(GS_OUT)
	mkdir $(GS_OUT)/chart

$(GS_TMP) :
	mkdir $(GS_TMP)

$(GS_TMP)/alpha : | $(GS_TMP)
	mkdir $(GS_TMP)/alpha

$(GS_OUT)/dags/%.png $(GS_OUT)/dags/%.map $(GS_OUT)/dags/%.plain : $(ARTICLES) $(GS_OUT)/dv.db ./dag.pl | $(GS_OUT)/dags
	./dag.pl $* $(GS_OUT)/dags/ $(GS_OUT)/dv.db

./alpha_shape : alpha_shape.c
	g++ alpha_shape.c -o alpha_shape -lCGAL -lgmp -frounding-math -g `Magick++-config --cppflags --cxxflags --ldflags --libs`

$(GS_TMP)/alpha/%.alpha_shape : $(GS_TMP)/alpha/%.mask.png ./alpha_shape
	./alpha_shape $@ $<

$(GS_TMP)/alpha/%.alpha.png $(GS_TMP)/alpha/%.mask.png : $(GS_IMG)/victimpics/%.gif  alpha_data/%.alpha | $(GS_TMP)/alpha
	./alpha.pl -target $(GS_TMP)/alpha/$*.alpha.png -file $< -alpha "alpha_data/$*.alpha"
	convert $(GS_TMP)/alpha/$*.alpha.png -alpha extract $(GS_TMP)/alpha/$*.mask.png
	feather -d $(FEATHER_SIZE) $(GS_TMP)/alpha/$*.mask.png $(GS_TMP)/alpha/$*.mask.png
	convert $(GS_TMP)/alpha/$*.alpha.png $(GS_TMP)/alpha/$*.mask.png -alpha Off -compose CopyOpacity -composite $(GS_TMP)/alpha/$*.alpha.png

$(GS_TMP)/alpha/%.alpha.png $(GS_TMP)/alpha/%.mask.png : $(GS_TMP)/%.article alpha_done/%.mask.png ./alpha_done.pl | $(GS_TMP)/alpha
	cp alpha_done/$*.mask.png $(GS_TMP)/alpha/$*.mask.png 
	./alpha_done.pl $(GS_TMP)/alpha/$*.alpha.png $* $< alpha_done/$*.mask.png 
	#feather -d $(FEATHER_SIZE) $(GS_TMP)/alpha/$*.mask.png $(GS_TMP)/alpha/$*.mask.png
	convert $(GS_TMP)/alpha/$*.alpha.png $(GS_TMP)/alpha/$*.mask.png -alpha Off -compose CopyOpacity -composite $(GS_TMP)/alpha/$*.alpha.png

$(GS_TMP)/alpha/%.alpha.png $(GS_TMP)/alpha/%.mask.png : $(GS_TMP)/%.article alpha_data/%.alpha  \
			      ./alpha.pl | $(GS_TMP)/alpha
	./alpha.pl -target $(GS_TMP)/alpha/$*.alpha.png -article $< -alpha "alpha_data/$*.alpha"
	convert $(GS_TMP)/alpha/$*.alpha.png -alpha extract $(GS_TMP)/alpha/$*.mask.png
	feather -d $(FEATHER_SIZE) $(GS_TMP)/alpha/$*.mask.png $(GS_TMP)/alpha/$*.mask.png
	convert $(GS_TMP)/alpha/$*.alpha.png $(GS_TMP)/alpha/$*.mask.png -alpha Off -compose CopyOpacity -composite $(GS_TMP)/alpha/$*.alpha.png

$(GS_OUT)/reunion.png $(GS_OUT)/reunion.json: $(ALPHAS) $(ALPHA_SHAPES) ./composite.pl | $(GS_OUT)
	./composite.pl

$(GS_OUT)/tiles/reunion : $(GS_OUT)/reunion.png ./create_tiles.pl
	nice ./create_tiles.pl -v --path $(GS_OUT)/tiles $(GS_OUT)/reunion.png

graph : $(GS_OUT)/tiles/all $(GS_OUT)/dags/all_poly.js
	@echo "Graph"

$(GS_OUT)/tiles/all : $(GS_OUT)/dags/all.png ./create_tiles.pl
	nice ./create_tiles.pl -v --path $(GS_OUT)/tiles $(GS_OUT)/dags/all.png

$(GS_OUT)/dags/all_poly.js : ./poly.pl $(GS_OUT)/dags/all.plain $(GS_OUT)/dags/all.png $(GS_OUT)/dags/all.map | $(GS_OUT)/dags/
	./poly.pl $(GS_OUT)/dv.db $(GS_OUT)/dags/all.png $(GS_OUT)/dags/all.plain $(GS_OUT)/dags/all.map $@

$(GS_TMP)/%.article : archive.gamespy.com/Dailyvictim/index.asp_id_%.html \
	archive.gamespy.com/comics/DailyVictim/vote.asp_id_%_dontvote_true ./article.pl | $(GS_TMP)
	./article.pl $@ $* $^

$(GS_TMP)/%.article : $(MIRROR)/%.html $(MIRROR)/%.vote.html ./article.pl | $(GS_TMP)
	./article.pl $@ $* $^

$(GS_TMP)/%.article : $(MIRROR)/%.html ./article.pl | $(GS_TMP)
	./article.pl $@ $* $< "NO VOTE DATA"

$(GS_OUT)/dv.db : $(ARTICLES) $(VOTES) ./loaddb.pl \
	$(MIRROR)/anatofvictim.1.html $(MIRROR)/anatofvictim.2.html \
	$(MIRROR)/anatofvictim.3.html $(MIRROR)/anatofvictim.4.html \
	$(MIRROR)/anatofvictim.5.html $(MIRROR)/top10.1.html $(MIRROR)/top10.2.html \
	$(MIRROR)/top10.3.html $(MIRROR)/top10.4.html | $(GS_OUT)
	rm $(GS_OUT)/dv.db || true
	./loaddb.pl $(GS_OUT)/dv.db $(GS_TMP) mirror || rm $(GS_OUT)/dv.db

%.pl : gs_shared.pl

stage: all
	rsync --exclude '*~' $(GS_OUT)/* $(GS_IMG) site/* "$(HOST):$(STAGE)" -r

live: stage
	ssh $(HOST) 'rsync --delete "$(STAGE)" "$(LIVE)" -r'
