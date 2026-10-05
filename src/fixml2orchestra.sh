# Convert standard FIXML schemata back to Orchestra
# Author: Hanno Klein, Senior Advisor, FIXdom Germany

# First parameter is a supported FIX version (FIX44, FIXLatest)
# Second parameter is the name of the file with the Orchestra metadata element

jarfile="../lib/SaxonHE12-9J/saxon-he-12.9.jar"
mkdir -p ../output

# Start timer to show duration later
echo "STARTED $(date)"
startEpoch=$(date '+%s')

echo "Transforming $1.xml from FIXML to Orchestra..."
java -jar "$jarfile" -xsl:fixml2orchestra.xsl -it version=$1 subversion="$2" metadata-file="$3" > "../output/Orchestra$1.xml"

# Remove the FIXML namespace declaration from the NoXXX field definitions
sed -i '' '/<fixml:FIXMLencodingType/{N;s/\n[[:space:]]*/ /;s/ xmlns:fixml="[^"]*"//;}' "../output/Orchestra$1.xml"

echo "\nENDED $(date)"
endEpoch=$(date '+%s')
duration=$((endEpoch - startEpoch))
echo "$duration seconds"
