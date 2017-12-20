#!/bin/bash

cut -f1 -d" " $1/i0.*/word_mapper | sort -u > $1/word_map_words
