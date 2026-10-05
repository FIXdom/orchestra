<?xml version="1.0" encoding="UTF-8"?>
<!-- Author: Hanno Klein, Senior Advisor, FIXdom Germany -->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:fixr="http://fixprotocol.io/2020/orchestra/repository"
  xmlns:xs="http://www.w3.org/2001/XMLSchema">

  <xsl:param name="elementType" as="xs:string"/>
  <xsl:param name="outputFile" as="xs:string"/>

  <xsl:template match="/">
    <xsl:result-document href="{$outputFile}" method="text" encoding="UTF-8">
      <xsl:for-each-group select="//*[local-name() = $elementType
          and namespace-uri() = 'http://fixprotocol.io/2020/orchestra/repository']"
          group-by="@id">
          <xsl:sort select="current-grouping-key()" data-type="number" order="ascending"/>
          <xsl:variable name="element" select="current-group()[1]"/>
          <xsl:value-of select="$element/@id"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="$element/@name"/>
          <xsl:if test="$elementType = 'message'">
            <xsl:text> </xsl:text>
            <xsl:value-of select="$element/@msgType"/>
          </xsl:if>
          <xsl:if test="$elementType = 'group'">
            <xsl:text> </xsl:text>
            <xsl:value-of select="./fixr:numInGroup/@id"/>
          </xsl:if>
          <xsl:if test="position() != last()">
            <xsl:text>&#10;</xsl:text>
          </xsl:if>
        </xsl:for-each-group>
    </xsl:result-document>
   </xsl:template>

</xsl:stylesheet>
