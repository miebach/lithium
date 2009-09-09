vpath %.lfe  ./src
vpath %.erl  ./src
vpath %.lfe  ./src/pages
vpath %.lfe  ./include
vpath %.beam ./ebin
vpath %.beam ./lib/lfe/ebin
vpath %.beam ./lib/nitrogen/ebin
vpath %.beam ./lib/mochiweb/ebin
vpath %.beam ./lib/hrl-to-lfe


LSRCS=lithium_app.lfe web_blog.lfe   web_index2.lfe  web_link.lfe  web_sort.lfe  web_vote.lfe web_calc.lfe  web_counter.lfe  web_index.lfe   web_piki.lfe  web_viewsource.lfe

LOBJS=$(LSRCS:.lfe=.beam) 

.PHONY: all

all: lfe nitrogen mochiweb hrl-to-lfe wf.lfe $(LOBJS)

update: 
	git submodule init
	git submodule update

lfe: lfe_comp.beam
lfe_comp.beam:
	(cd lib/lfe ; make) 

nitrogen: wf.beam
wf.beam:
	(cd lib/nitrogen ; make)

hrl-to-lfe: h2l.beam
h2l.beam:
	(cd lib/hrl-to-lfe ; erl -make)

mochiweb: mochiweb.beam
mochiweb.beam:
	(cd lib/mochiweb ; make all)

WF=./lib/nitrogen/include/wf.inc
H2L=./lib/hrl-to-lfe/
wf.lfe:
	cat ${WF} | erl -pa ${H2L} -noshell -s h2l pipe > ./include/wf.lfe

ERL_LOAD='code:load_file(lfe_comp).'
ERL_COMP='File=hd(init:get_plain_arguments()), try lfe_comp:file(File,[report,{outdir,"ebin"}]) of {ok,_Module} -> halt(0); error -> halt(1); All ->  io:format("./~s:1: ~p~n",[File,All]) catch X:Y -> io:format("./~s:1: Catch outside of compiler: ~p ~p ~n",[File,X,Y]) end, halt(1).'

%.beam : %.erl
	erlc -o ebin $<

%.beam : %.lfe
	@echo Recompile: $<
	erl -pa ./lib/lfe/ebin -noshell -eval $(ERL_LOAD) -eval $(ERL_COMP) -extra $< 

start:
	@echo Starting Lithium. ${ERL_TOP}
	@erl \
	-name lithium@localhost \
	-pa ./ebin \
	-pa ./lib/lfe/ebin \
	-pa ./lib/nitrogen/ebin \
	-s make all \
	-eval "application:start(lithium)"


lclean: clean
	rm -rf compile.err compile.out *.dump 
clean: 
	rm -rf ./ebin/*.beam
	
wipe: clean lclean
	rm ./include/wf.lfe
	(cd lib/lfe ; make clean)
	(cd lib/nitrogen ; make clean)
	(cd lib/mochiweb ; make clean)
	(cd lib/h2l-to-lfe ; make clean)
	

FLY_BEAM=$(notdir $(CHK_SOURCES:.lfe=.beam))
BEAM=$(notdir $(CHK_SOURCES:_flymake.lfe=.beam)) 
MODULE=$(notdir $(CHK_SOURCES:_flymake.lfe=)) 

#	prerequisite 1. Only one screen, 2. run "screen","screen -t server1","sh start.sh" 
#	Install mozrepl for page reload, http://wiki.github.com/bard/mozrepl

check-syntax:
	erl -noshell -pa ${HOME}/elib/lfe/ebin -eval $(ERL_LOAD) -eval $(ERL_COMP) -extra $(CHK_SOURCES) 
#	If flymake-mode is not working, comment lines below.
	mv ebin/$(FLY_BEAM) ebin/$(BEAM)  >  compile.out 2> compile.err
	@screen -p server1 -X stuff $''code:purge($(MODULE)),code:load_file($(MODULE)).' \
		 >> compile.out 2>> compile.err
	@echo BrowserReload\(\)\; repl.quit\(\) | nc localhost 4242 >> compile.out 2>> compile.err


help:
	@echo ";; Copy to .emacs, then restart."
	@echo "(when (load \"flymake\" t)"
	@echo "  (setq flymake-log-level 3)"
	@echo "  (add-hook 'find-file-hook 'flymake-find-file-hook)"
	@echo "  (add-to-list 'flymake-allowed-file-name-masks"
	@echo "	       '(\"\\\\\.lfe\\\\\'\" flymake-simple-make-init)))"
	@echo ""
	@echo "(autoload 'moz-minor-mode \"moz\" \"Mozilla Minor and Inferior Mozilla Modes\" t)"
	@echo "(add-hook 'javascript-mode-hook 'javascript-custom-setup)"
	@echo "    (defun javascript-custom-setup ()"
	@echo "      (moz-minor-mode 1))"
	@echo "(global-set-key (kbd \"C-x p\")"
	@echo "                (lambda ()"
	@echo "                  (interactive)"
	@echo "                  (comint-send-string (inferior-moz-process)"
	@echo "                                      \"BrowserReload();\")))"

$(shell   mkdir -p ./lib/mochiweb/ebin)
