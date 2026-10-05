<?xml version="1.0" encoding="UTF-8"?>
<!-- Author: Hanno Klein, Senior Advisor, FIXdom Germany -->
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:fixr="http://fixprotocol.io/2020/orchestra/repository"
  xmlns:fixml="http://fixprotocol.io/2022/orchestra/appinfo/fixml"
  xmlns:fm="http://www.fixprotocol.org/FIXML-Latest/METADATA"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="xsl map">

  <xsl:param name="version" as="xs:string"/>
  <xsl:param name="subversion" as="xs:string"/>
  <xsl:param name="metadata-file" as="xs:string"/>

  <xsl:variable name="codes" select="concat('../lookup/Orchestra', $version, '-codes.txt')"/>
  <xsl:variable name="fields" select="concat('../lookup/Orchestra', $version, '-fields.txt')"/>
  <xsl:variable name="components" select="concat('../lookup/Orchestra', $version, '-components.txt')"/>
  <xsl:variable name="groups" select="concat('../lookup/Orchestra', $version, '-groups.txt')"/>
  <xsl:variable name="messages" select="concat('../lookup/Orchestra', $version, '-messages.txt')"/>

  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

  <!-- Load codes, fields, components, groups, and messages into lookup tables -->

  <!-- List of codes has ID and name (a.k.a. symbolic name) -->
  <xsl:variable name="code-name" as="map(xs:string, xs:string)"
      select="
          map:merge(
              tokenize(unparsed-text($codes), '\r?\n')
              [normalize-space(.)]
              ! map:entry(
                  string(tokenize(normalize-space(.), '\s+')[1]),
                  string(tokenize(normalize-space(.), '\s+')[2])
              )
          )
      "/>

  <!-- List of fields has ID and name -->
  <!-- Map allows lookup by ID or by name, returning name or ID -->
  <xsl:variable name="field-identifier" as="map(xs:string, xs:string)"
      select="
          map:merge(
              tokenize(unparsed-text($fields), '\r?\n')
              [normalize-space(.)]
              !
              (
                  map:entry(
                      tokenize(normalize-space(.), '\s+')[1],
                      tokenize(normalize-space(.), '\s+')[2]
                  ),
                  map:entry(
                      tokenize(normalize-space(.), '\s+')[2],
                      tokenize(normalize-space(.), '\s+')[1]
                  )
              )
          )
      "/>

  <!-- List of components has ID and name -->
  <xsl:variable name="component-identifier" as="map(xs:string, xs:string)"
      select="
          map:merge(
              tokenize(unparsed-text($components), '\r?\n')
              [normalize-space(.)]
              ! map:entry(
                  string(tokenize(normalize-space(.), '\s+')[2]),
                  string(tokenize(normalize-space(.), '\s+')[1])
              )
          )
      "/>

  <!-- List of groups has ID, name, and ID of NoXXX field -->
  <xsl:variable name="group-identifier" as="map(xs:string, xs:string*)"
      select="
          map:merge(
              tokenize(unparsed-text($groups), '\r?\n')
              [normalize-space(.)]
              ! map:entry(
                  string(tokenize(normalize-space(.), '\s+')[2]),
                  (
                    string(tokenize(normalize-space(.), '\s+')[1]),
                    string(tokenize(normalize-space(.), '\s+')[3])
                  )
              )
          )
      "/>

  <!-- List of messages has ID, name, and FIX message type -->
  <xsl:variable name="message-identifier" as="map(xs:string, xs:string*)"
      select="
          map:merge(
              tokenize(unparsed-text($messages), '\r?\n')
              [normalize-space(.)]
              ! map:entry(
                  string(tokenize(normalize-space(.), '\s+')[2]),
                  (
                    string(tokenize(normalize-space(.), '\s+')[1]),
                    string(tokenize(normalize-space(.), '\s+')[3])
                  )
              )
          )
      "/>

  <xsl:variable name="xsdDir" select="resolve-uri('../input/fixml/', static-base-uri())"/>

  <!-- Load FIXML schema file with datatypes into a variable. -->
  <xsl:variable name="FIXMLdatatypes"
    select="doc(resolve-uri(
        '../input/fixml/fixml-datatypes-Latest.xsd',
        static-base-uri()
    ))"/>

  <!-- Load FIXML schema file with fields into a variable. -->
  <xsl:variable name="FIXMLfields"
    select="doc(resolve-uri(
        '../input/fixml/fixml-fields-base-Latest.xsd',
        static-base-uri()
    ))"/>

  <!-- Load FIXML schema file with components and repeating groups into a variable. -->
  <!-- NOTE: FIXML schema has components and repeating groups in a single file. -->
  <xsl:variable name="FIXMLcomponents"
    select="doc(resolve-uri(
        '../input/fixml/fixml-components-base-Latest.xsd',
        static-base-uri()
    ))"/>

  <xsl:variable name="xsdFiles" select="collection(concat($xsdDir, '?select=*.xsd'))"/>

  <xsl:template name="xsl:initial-template">

    <fixr:repository xmlns:fixml="http://fixprotocol.io/2022/orchestra/appinfo/fixml">

      <xsl:attribute name="name"><xsl:value-of select="'FIX.Latest'"/></xsl:attribute>
      <xsl:attribute name="version"><xsl:value-of select="concat('FIX.Latest_',$subversion)"/></xsl:attribute>

      <xsl:copy-of select="document(concat('../input/', $metadata-file, '.xml'))/*"/>

      <!-- NOTE: A category must always belong to the same section (Orchestra v1.0) -->
      <!-- NOTE: Category "Session" is not relevant for FIXML but added here for convenience. -->
      <fixr:categories>
        <xsl:for-each-group
            select="$xsdFiles/xs:schema/xs:complexType/xs:annotation/xs:appinfo/fm:Xref[@ComponentType='Message']"
            group-by="@Category">
            <xsl:sort select="@Category" order="ascending"/>
            <fixr:category name="{current-grouping-key()}" section="{current-group()[1]/@Section}"
                           componentType="Message" includeFile="components"/>
        </xsl:for-each-group>
        <fixr:category name="Session" FIXMLFileName="session" componentType="Message" section="Session">
          <fixr:annotation>
            <fixr:appinfo purpose="FIXML">
              <fixml:FIXMLencodingType notReqXML="1" />
            </fixr:appinfo>
          </fixr:annotation>
        </fixr:category>
      </fixr:categories>

      <!-- NOTE: Section "Session" is not relevant for FIXML but added here for convenience. -->
      <fixr:sections>
        <xsl:for-each select="distinct-values(
            $xsdFiles/xs:schema/xs:complexType/xs:annotation/xs:appinfo/fm:Xref[@ComponentType='Message']/@Section)">
            <xsl:sort select="." order="ascending"/>
            <fixr:section name="{.}" FIXMLFileName="{lower-case(.)}"/>
        </xsl:for-each>
        <fixr:section name="Session" FIXMLFileName="session">
          <fixr:annotation>
            <fixr:appinfo purpose="FIXML">
              <fixml:FIXMLencodingType notReqXML="1"/>
            </fixr:appinfo>
          </fixr:annotation>
        </fixr:section>
      </fixr:sections>

      <fixr:datatypes>
        <xsl:for-each select="$FIXMLdatatypes/xs:schema/xs:simpleType">
          <xsl:sort select="@name" order="ascending"/>
          <xsl:variable name="builtin" select="if (@name = ('int','float','String')) then ('true') else ('false')"/>
          <fixr:datatype name="{@name}">
            <fixr:mappedDatatype standard="XML" builtin="{$builtin}" base="{xs:restriction/@base}">
              <xsl:if test="xs:restriction/xs:pattern">
                <xsl:attribute name="pattern"><xsl:value-of select="xs:restriction/xs:pattern/@value"/></xsl:attribute>
              </xsl:if>
            </fixr:mappedDatatype>
            <fixr:annotation>
              <fixr:documentation purpose="SYNOPSIS"><xsl:value-of select="normalize-space(.)"/></fixr:documentation>
            </fixr:annotation>
          </fixr:datatype>
        </xsl:for-each>
      </fixr:datatypes>

      <!-- FIXML schema does not have symbolic names, requires lookup. -->
      <fixr:codeSets>
        <xsl:for-each select="$FIXMLfields/xs:schema/xs:simpleType/xs:annotation/xs:appinfo/fm:Xref[@ComponentType='Field']">
          <xsl:sort select="@name" order="ascending"/>
          <xsl:if test="../../../xs:restriction/xs:enumeration">
            <xsl:variable name="tag" select="@Tag"/>
            <fixr:codeSet id="{$tag}" name="{concat(@name,'CodeSet')}" type="{@Type}">
              <xsl:for-each select="../../xs:appinfo[2]/fm:EnumDoc">
                <xsl:variable name="id" select="concat($tag,format-number(position(), '000'))"/>
                <fixr:code id="{$id}" value="{@value}" name="{$code-name($id)}">
                  <fixr:annotation>
                    <fixr:documentation purpose="SYNOPSIS"><xsl:value-of select="."/></fixr:documentation>
                  </fixr:annotation>
                </fixr:code>
              </xsl:for-each>
            </fixr:codeSet>
          </xsl:if>
        </xsl:for-each>
      </fixr:codeSets>

      <fixr:fields>
        <xsl:for-each select="$FIXMLfields/xs:schema/xs:simpleType/xs:annotation/xs:appinfo/fm:Xref[@ComponentType='Field']">
          <xsl:sort select="@Tag" data-type="number" order="ascending"/>
          <fixr:field id="{@Tag}" name="{@name}" abbrName="{@AbbrName}">
            <xsl:attribute name="type">
              <xsl:choose>
                <xsl:when test="../../../xs:restriction/xs:enumeration"><xsl:value-of select="concat(@name,'CodeSet')"/></xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="@Type"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:attribute>
            <fixr:annotation>
              <fixr:documentation purpose="SYNOPSIS"><xsl:value-of select="../../xs:documentation"/></fixr:documentation>
            </fixr:annotation>
          </fixr:field>
        </xsl:for-each>
        <!-- NumInGroup fields are not required by FIXML but added for convenience at the end. -->
        <!-- NOTE: One NoXXX field may be used by multiple repeating groups. -->
        <xsl:for-each-group select="$xsdFiles/xs:schema/xs:complexType/xs:annotation/xs:appinfo/fm:Xref[@ComponentType='BlockRepeating']"
          group-by="$field-identifier($group-identifier(@name)[2])">
          <xsl:sort select="$group-identifier(@name)[2]" order="ascending"/>
          <xsl:variable name="groupName" select="$group-identifier(@name)[2]"/>
          <fixr:field id="{$groupName}" name="{$field-identifier($groupName)}" type="NumInGroup">
            <fixr:annotation>
              <fixr:appinfo purpose="FIXML">
                <fixml:FIXMLencodingType notReqXML="1"/>
              </fixr:appinfo>
            </fixr:annotation>
          </fixr:field>
        </xsl:for-each-group>
        <!-- StandardTrailer is not relevant for FIXML but CheckSum(10) added here for convenience. -->
        <fixr:field id="10" name="CheckSum" abbrName="CheckSum" type="String">
          <fixr:annotation>
            <fixr:documentation purpose="SYNOPSIS">Three byte, simple checksum (see Volume 2: "Checksum Calculation" for description). ALWAYS LAST FIELD IN MESSAGE; i.e. serves, with the trailing &lt;SOH&gt;, as the end-of-message delimiter. Always defined as three characters. (Always unencrypted)</fixr:documentation>
            <fixr:appinfo purpose="FIXML">
              <fixml:FIXMLencodingType notReqXML="1" />
            </fixr:appinfo>
          </fixr:annotation>
        </fixr:field>
      </fixr:fields>

      <!-- Names of component elements are added for convenience (supported by Orchestra v1.1) -->
      <!-- NOTE: StandardTrailer is not relevant for FIXML but added here for convenience. -->
      <fixr:components>
        <xsl:for-each select="$xsdFiles/xs:schema/xs:complexType/xs:annotation/xs:appinfo/fm:Xref[@ComponentType=('Block','XMLDataBlock')]">
          <xsl:sort select="@name" order="ascending"/>
          <xsl:variable name="complexType" select="../../../@name"/>
          <fixr:component id="{$component-identifier(@name)}" name="{@name}"
                          abbrName="{../../../../xs:group/xs:sequence/xs:element[@type = $complexType]/@name}"
                          category="{@Category}">
            <xsl:variable name="component" select="if (@name = 'StandardHeader') then ('BaseHeaderAttributes') else (concat(@name, 'Attributes'))"/>
            <xsl:for-each select="$xsdFiles/xs:schema/xs:attributeGroup[@name=$component]/xs:attribute">
              <xsl:call-template name="field-ref">
                <xsl:with-param name="field-name" select="replace(@type, '_t$', '')"/>
                <xsl:with-param name="required" select="@use = 'required'"/>
              </xsl:call-template>
            </xsl:for-each>
            <xsl:variable name="group" select="concat(@name, 'Elements')"/>
            <xsl:for-each select="$xsdFiles/xs:schema/xs:group[@name=$group]/xs:sequence/xs:element">
              <xsl:call-template name="component-or-group-ref">
                <xsl:with-param name="name" select="replace(@type, '_Block_t$', '')"/>
                <xsl:with-param name="required" select="@minOccurs = '1'"/>
              </xsl:call-template>
            </xsl:for-each>
          </fixr:component>
        </xsl:for-each>
        <fixr:component id="1025" name="StandardTrailer" abbrName="Trlr" category="Session">
          <fixr:fieldRef id="10" presence="required">
            <fixr:annotation>
              <fixr:appinfo purpose="FIXML">
                <fixml:FIXMLencodingType notReqXML="1" />
              </fixr:appinfo>
              <fixr:documentation purpose="SYNOPSIS">The standard FIX message trailer</fixr:documentation>
            </fixr:annotation>
          </fixr:fieldRef>
        </fixr:component>
      </fixr:components>

      <!-- Names of group elements are added for convenience (supported by Orchestra v1.1) -->
      <fixr:groups>
        <xsl:for-each select="$xsdFiles/xs:schema/xs:complexType/xs:annotation/xs:appinfo/fm:Xref[@ComponentType='BlockRepeating']">
          <xsl:sort select="@name" order="ascending"/>
          <xsl:variable name="complexType" select="../../../@name"/>
          <fixr:group id="{$group-identifier(@name)}" name="{@name}"
                      abbrName="{../../../../xs:group/xs:sequence/xs:element[@type = $complexType]/@name}"
                      category="{@Category}">
            <fixr:numInGroup id="{$group-identifier(@name)[2]}" name="{$field-identifier($group-identifier(@name)[2])}"/>
            <xsl:variable name="component" select="if (@name = 'StandardHeader') then ('BaseHeaderAttributes') else (concat(@name, 'Attributes'))"/>
            <xsl:for-each select="$xsdFiles/xs:schema/xs:attributeGroup[@name=$component]/xs:attribute">
              <xsl:call-template name="field-ref">
                <xsl:with-param name="field-name" select="replace(@type, '_t$', '')"/>
                <xsl:with-param name="required" select="@use = 'required'"/>
              </xsl:call-template>
            </xsl:for-each>
            <xsl:variable name="group" select="concat(@name, 'Elements')"/>
            <xsl:for-each select="$xsdFiles/xs:schema/xs:group[@name=$group]/xs:sequence/xs:element">
              <xsl:call-template name="component-or-group-ref">
                <xsl:with-param name="name" select="replace(@type, '_Block_t$', '')"/>
                <xsl:with-param name="required" select="@minOccurs = '1'"/>
              </xsl:call-template>
            </xsl:for-each>
          </fixr:group>
        </xsl:for-each>
      </fixr:groups>

      <!-- FIXML does not explicitly include header and trailer components to each message as they are optional. -->
      <!-- FIXML does not have the FIX message types, lookup required. -->
      <!-- NOTE: FIX Session Layer messages are not included. -->
      <fixr:messages>
        <xsl:for-each select="$xsdFiles/xs:schema/xs:complexType/xs:annotation/xs:appinfo/fm:Xref[@ComponentType='Message']">
          <xsl:sort select="@name" order="ascending"/>
          <xsl:variable name="complexType" select="../../../@name"/>
          <fixr:message id="{@MsgID}" name="{@name}" msgType="{$message-identifier(@name)[2]}"
                        abbrName="{../../../../xs:element[@type = $complexType]/@name}" category="{@Category}">
            <fixr:structure>
              <fixr:componentRef id="{$component-identifier('StandardHeader')}" name="StandardHeader" presence="required"/>
              <xsl:variable name="component" select="concat(@name, 'Attributes')"/>
              <xsl:for-each select="$xsdFiles/xs:schema/xs:attributeGroup[@name=$component]/xs:attribute">
                <xsl:call-template name="field-ref">
                  <xsl:with-param name="field-name" select="replace(@type, '_t$', '')"/>
                  <xsl:with-param name="required" select="@use = 'required'"/>
                </xsl:call-template>
              </xsl:for-each>
              <xsl:variable name="group" select="concat(@name, 'Elements')"/>
              <xsl:for-each select="$xsdFiles/xs:schema/xs:group[@name=$group]/xs:sequence/xs:element">
                <xsl:call-template name="component-or-group-ref">
                  <xsl:with-param name="name" select="replace(@type, '_Block_t$', '')"/>
                  <xsl:with-param name="required" select="@minOccurs = '1'"/>
                </xsl:call-template>
              </xsl:for-each>
              <fixr:componentRef id="{$component-identifier('StandardTrailer')}" name="StandardTrailer" presence="required"/>
            </fixr:structure>
          </fixr:message>
        </xsl:for-each>
      </fixr:messages>
    </fixr:repository>
  </xsl:template>

  <xsl:template name="field-ref">
    <xsl:param name="field-name"/><xsl:param name="isRequired"/>
    <fixr:fieldRef id="{$field-identifier($field-name)}" name="{$field-name}">
      <xsl:if test="$isRequired">
        <xsl:attribute name="presence" select="'required'"/>
      </xsl:if>
    </fixr:fieldRef>
  </xsl:template>

  <xsl:template name="component-or-group-ref">
    <xsl:param name="name"/><xsl:param name="isRequired"/>
    <xsl:choose>
      <xsl:when test="@maxOccurs = '1'">
        <fixr:componentRef id="{$component-identifier($name)}" name="{$name}">
          <xsl:if test="@isRequired">
            <xsl:attribute name="presence" select="'required'"/>
          </xsl:if>
        </fixr:componentRef>
      </xsl:when>
      <xsl:when test="@maxOccurs != '1'">
        <fixr:groupRef id="{$group-identifier($name)}" name="{$name}">
          <xsl:if test="@isRequired">
            <xsl:attribute name="presence" select="'required'"/>
          </xsl:if>
        </fixr:groupRef>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
