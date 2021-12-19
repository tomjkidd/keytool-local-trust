#!/usr/bin/env bash

# Initially, I was using straight ansi escape codes to handle colors, but it turns
# out tput is a way nicer interface.

# ==============================
# ANSI color notes and resources
# ==============================
# https://stackoverflow.com/questions/4842424/list-of-ansi-color-escape-sequences
# https://robotmoon.com/256-colors/#xterm-color-codes
#
# The following were able to be used in a Makefile and called with echo
# Blue=\033[38;5;27m
# Blue=\033[38;5;69m
# Blue=\033[38;5;39m
# None=\033[0m
# `@echo "$(Blue)This text should be blue$(None) This text should return to default"`

# ==============================
# tput color notes and resources
# ==============================
# https://www.linuxcommand.org/lc3_adv_tput.php
# The following snippet was modified to use 255 colors, so that you get
# a sense of the colors available on a given system

# tput_colors - Demonstrate color combinations.
for fg_color in {0..255}; do
    set_foreground=$(tput setaf $fg_color)
    for bg_color in {0..7}; do
        set_background=$(tput setab $bg_color)
        echo -n $set_background$set_foreground
        printf ' F:%s B:%s ' $fg_color $bg_color
    done
    echo $(tput sgr0)
done
