# Author: Hanno Klein, Senior Advisor, FIXdom Germany

# First parameter is the source file

jarfile="../lib/SaxonHE12-9J/saxon-he-12.9.jar"
mkdir -p ../target

# Start timer to show duration later
echo "STARTED $(date)"
startEpoch=$(date '+%s')

echo "Extracting elements from Orchestra file $1.xml..."
java -jar "$jarfile" -xsl:extractElements.xsl -s:"../input/$1.xml" elementType="message" > ../target/"$1-messages.txt"
java -jar "$jarfile" -xsl:extractElements.xsl -s:"../input/$1.xml" elementType="group" > ../target/"$1-groups.txt"
java -jar "$jarfile" -xsl:extractElements.xsl -s:"../input/$1.xml" elementType="component" > ../target/"$1-components.txt"
java -jar "$jarfile" -xsl:extractElements.xsl -s:"../input/$1.xml" elementType="field" > ../target/"$1-fields.txt"
java -jar "$jarfile" -xsl:extractElements.xsl -s:"../input/$1.xml" elementType="codeSet" > ../target/"$1-codeSets.txt"

echo "\nENDED $(date)"
endEpoch=$(date '+%s')
duration=$((endEpoch - startEpoch))
echo "$duration seconds"
