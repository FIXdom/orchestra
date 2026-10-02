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
      <xsl:for-each select="//*[local-name() = $elementType
          and namespace-uri() = 'http://fixprotocol.io/2020/orchestra/repository']">
          <xsl:sort select="@id" data-type="number" order="ascending"/>
          <xsl:value-of select="@id"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="@name"/>
          <xsl:if test="position() != last()">
            <xsl:text>&#10;</xsl:text>
          </xsl:if>
        </xsl:for-each>
    </xsl:result-document>
   </xsl:template>

</xsl:stylesheet>
