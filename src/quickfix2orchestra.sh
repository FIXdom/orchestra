# Author: Hanno Klein, Senior Advisor, FIXdom Germany

# First parameter is the source file
# Second parameter is a supported FIX version (FIX42, FIX44, FIXLatest)
# Third parameter is the name of the file with the Orchestra metadata element

jarfile="../lib/SaxonHE12-9J/saxon-he-12.9.jar"
mkdir -p ../output

# Start timer to show duration later
echo "STARTED $(date)"
startEpoch=$(date '+%s')

echo "Transforming $1.xml from QuickFIX to Orchestra..."
java -jar "$jarfile" -xsl:quickfix2orchestra.xsl -s:"../input/$1.xml" version=$2 metadata-file="$3" > "../output/$1-O.xml"

echo "\nENDED $(date)"
endEpoch=$(date '+%s')
duration=$((endEpoch - startEpoch))
echo "$duration seconds"
