#!/bin/bash
[ ! $(which ffplay) ] && { echo ffplay is necessary to run this. Maybe you can install it with: 'brew install --with-ffplay --with-freetext ffmpeg'; exit 1 ;};

usage(){
	echo "
	$(basename $0)
	
	usage: $(basename $0) [ filteroption ] [ -o outputfile ] inputfile
	
	filter options:
	-f		split field mode
	-c		channel split mode
	-d		field difference mode. midtone gray means no difference in between fields
	-w		field waveform mode, waveforms per channel per field
	-v		field vectrscope mode, vectroscopes per field
	-l		field histogram mode, histograms per field
	-i		highlight interlacement artifacts
	
	optional output:
	-o		outputfile
	
	"
}

# filter recipes
fieldsplitplay="-vf 'split[a][b]; [a]pad=iw:ih*2,field=top[src]; [b]field=bottom[filt]; [src][filt]overlay=0:h'"
fielddiffplay="-vf 'split=4[a][b][c][d]; [a]pad=iw:ih*3,field=top[src]; [b]field=bottom[filt];[c]field=bottom[bb];[d]field=top,negate[tb];[src][filt]overlay=0:h[upper];[bb][tb]blend=all_mode=average[blend];[upper][blend]overlay=0:h*2'"
fieldwaveformplay="-vf 'split=4[a][b][c][d]; [a]pad=iw*2:ih*4,field=top[top]; [b]field=bottom[bot]; [top][bot]overlay=w[rowa];[c]field=top,histogram=mode=waveform:waveform_mode=column,pad=iw*2[rowba];[d]field=bottom,histogram=mode=waveform:waveform_mode=column[rowbb];[rowba][rowbb]overlay=w[rowb];[rowa][rowb]overlay=0:h/3'"
fieldhistogramplay="-vf 'split=4[a][b][c][d]; [a]pad=iw*2:ih*4,field=top[top]; [b]field=bottom[bot]; [top][bot]overlay=w[rowa];[c]field=top,histogram,scale=720,pad=iw*2[rowba];[d]field=bottom,histogram,scale=720[rowbb];[rowba][rowbb]overlay=w[rowb];[rowa][rowb]overlay=0:h/2'"
fieldvectroscopeplay="-vf 'split=4[a][b][c][d]; [a]pad=iw*2:ih*3,field=top[top]; [b]field=bottom[bot]; [top][bot]overlay=w[rowa];[c]field=top,histogram=mode=color,pad=iw*2[rowba];[d]field=bottom,histogram=mode=color[rowbb];[rowba][rowbb]overlay=w[rowb];[rowa][rowb]overlay=0:h'"
chromasplitplay="-vf 'split=4[a][b][c][d];[a]pad=iw*4:ih[w];[b]lutyuv=u=128:v=128[x];[c]lutyuv=y=128:v=128,curves=strong_contrast[y];[d]lutyuv=y=128:u=128,curves=strong_contrast[z];[w][x]overlay=w:0[wx];[wx][y]overlay=w*2:0[wxy];[wxy][z]overlay=w*3:0'"
interlaceplay="-vf 'kerndeint=map=1'"

[ "$#" = 0 ] && { usage ; exit 1 ;};
while getopts fcdwvilo:h opt ; do
	case "$opt" in
		f) filter="$fieldsplitplay" ;;
		d) filter="$fielddiffplay" ;;
		c) filter="$chromasplitplay" ;;
		w) filter="$fieldwaveformplay" ;;
		v) filter="$fieldvectroscopeplay" ;;
		i) filter="$interlaceplay" ;;
		l) filter="$fieldhistogramplay" ;;
		o) outputfile="$OPTARG" ;;
		h) usage ; exit 1 ;;
		\?) usage ; exit 1 ;;
	esac
done
shift $(( ${OPTIND} - 1 ))
inputfile="$1"
[ ! -f "$inputfile" ] && { echo No input file detected. ; usage ; exit 1 ;};
[ -n "$outputfile" ] && command="ffmpeg -i $inputfile $filter $outputfile" || command="ffplay $inputfile $filter"
echo "Running: $command"
eval "$command"