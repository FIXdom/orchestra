# Author: Hanno Klein, Senior Advisor, FIXdom Germany

# First parameter is the source file that may have a path

jarfile="../lib/SaxonHE12-9J/saxon-he-12.9.jar"
filename="${1##*/}"
mkdir -p ../target

# Start timer to show duration later
echo "STARTED $(date)"
startEpoch=$(date '+%s')

echo "Extracting elements from Orchestra file $1.xml..."
java -jar "$jarfile" -xsl:extractElements.xsl -s:"$1.xml" elementType="message" outputFile="../target/$filename-messages.txt"
java -jar "$jarfile" -xsl:extractElements.xsl -s:"$1.xml" elementType="group" outputFile="../target/$filename-groups.txt"
java -jar "$jarfile" -xsl:extractElements.xsl -s:"$1.xml" elementType="component" outputFile="../target/$filename-components.txt"
java -jar "$jarfile" -xsl:extractElements.xsl -s:"$1.xml" elementType="field" outputFile="../target/$filename-fields.txt"
java -jar "$jarfile" -xsl:extractElements.xsl -s:"$1.xml" elementType="codeSet" outputFile="../target/$filename-codeSets.txt"
java -jar "$jarfile" -xsl:extractElements.xsl -s:"$1.xml" elementType="code" outputFile="../target/$filename-codes.txt"

echo "\nENDED $(date)"
endEpoch=$(date '+%s')
duration=$((endEpoch - startEpoch))
echo "$duration seconds"
