#!/bin/bash


# ffmpeg -i frame%04d.png -vcodec libx264 movie.mpg

ffmpeg -f lavfi -i color=white:s=1920x1080 -i frame%04d.png -filter_complex overlay -vframes 30 -vcodec libx264 movie.mpg


