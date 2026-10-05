<?xml version="1.0" encoding="UTF-8"?>
<!-- Author: Hanno Klein, Senior Advisor, FIXdom Germany -->
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:fixr="http://fixprotocol.io/2020/orchestra/repository"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="xsl map">

  <xsl:param name="version" as="xs:string"/>
  <xsl:param name="metadata-file" as="xs:string"/>

  <xsl:variable name="components" select="concat('../lookup/Orchestra', $version, '-components.txt')"/>
  <xsl:variable name="groups" select="concat('../lookup/Orchestra', $version, '-groups.txt')"/>
  <xsl:variable name="messages" select="concat('../lookup/Orchestra', $version, '-messages.txt')"/>

  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

  <!-- Load names of fields, components and groups into a list -->
  <xsl:key name="field-by-name" match="fix/fields/field" use="@name"/>
  <xsl:key name="component-by-name" match="fix/components/component[not (count(*) = 1 and group)]" use="@name"/>
  <xsl:key name="group-by-name" match="fix/components/component/group" use="../@name"/>

  <!-- Load names of components, groups, and messages into lookup tables -->
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

  <xsl:variable name="group-identifier" as="map(xs:string, xs:string)"
      select="
          map:merge(
              tokenize(unparsed-text($groups), '\r?\n')
              [normalize-space(.)]
              ! map:entry(
                  string(tokenize(normalize-space(.), '\s+')[2]),
                  string(tokenize(normalize-space(.), '\s+')[1])
              )
          )
      "/>

  <xsl:variable name="message-identifier" as="map(xs:string, xs:string)"
      select="
          map:merge(
              tokenize(unparsed-text($messages), '\r?\n')
              [normalize-space(.)]
              ! map:entry(
                  string(tokenize(normalize-space(.), '\s+')[2]),
                  string(tokenize(normalize-space(.), '\s+')[1])
              )
          )
      "/>

  <!-- TODO
    NONE
  -->

  <xsl:template match="/">

    <fixr:repository>

      <xsl:attribute name="name">
        <xsl:value-of select="concat('FIX.', /fix/@major,
          if (/fix/@minor != '') then concat('.', /fix/@minor) else '',
          if (/fix/@servicepack = '1' or /fix/@servicepack = '2') then concat('SP', /fix/@servicepack) else '')
          "/>
      </xsl:attribute>

      <xsl:attribute name="version">
        <xsl:value-of select="concat('FIX.', /fix/@major,
          if (/fix/@minor != '') then concat('.', /fix/@minor) else '',
          if (/fix/@servicepack = '1' or /fix/@servicepack = '2') then concat('SP', /fix/@servicepack) else '',
          if (/fix/@extensionpack != '') then concat('_EP', /fix/@extensionpack) else '')
          "/>
      </xsl:attribute>

      <xsl:copy-of select="document(concat('../input/', $metadata-file, '.xml'))/*"/>

      <fixr:datatypes>
        <xsl:for-each select="/fix/fields/field[not(@type = preceding-sibling::field/@type)]">
          <xsl:call-template name="datatype">
            <xsl:with-param name="quickfix-type" select="@type"/>
          </xsl:call-template>
        </xsl:for-each>
      </fixr:datatypes>

      <fixr:codeSets>
        <xsl:for-each select="/fix/fields/field[value]">
          <fixr:codeSet name="{concat(@name,'CodeSet')}">
            <xsl:attribute name="id"><xsl:value-of select="@number"/></xsl:attribute>
            <xsl:attribute name="type">
              <xsl:call-template name="datatype-name">
                <xsl:with-param name="quickfix-type" select="@type"/>
              </xsl:call-template>
            </xsl:attribute>
            <xsl:for-each select="value">
              <fixr:code value="{@enum}" name="{@description}">
                <xsl:attribute name="id">
                  <xsl:value-of select="concat(../@number,format-number(position(), '000'))"/>
                </xsl:attribute>
              </fixr:code>
            </xsl:for-each>
          </fixr:codeSet>
        </xsl:for-each>
      </fixr:codeSets>

      <fixr:fields>
        <xsl:for-each select="/fix/fields/field">
          <fixr:field id="{@number}" name="{@name}">
            <xsl:attribute name="type">
              <xsl:choose>
                <xsl:when test="value"><xsl:value-of select="concat(@name,'CodeSet')"/></xsl:when>
                <xsl:otherwise>
                  <xsl:call-template name="datatype-name">
                    <xsl:with-param name="quickfix-type" select="@type"/>
                  </xsl:call-template>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:attribute>
          </fixr:field>
        </xsl:for-each>
      </fixr:fields>

      <!-- Special handling for header and trailer when not defined as normal component. -->
      <fixr:components>
        <xsl:if test="exists(/fix/header/field)">
          <fixr:component id="{$component-identifier('StandardHeader')}" name="StandardHeader">
            <xsl:for-each select="/fix/header/field">
              <xsl:call-template name="field-ref">
                <xsl:with-param name="field-name" select="@name"/>
                <xsl:with-param name="required" select="@required"/>
              </xsl:call-template>
            </xsl:for-each>
          </fixr:component>
        </xsl:if>

        <xsl:for-each select="/fix/components/component[not (count(*) = 1 and group)]">
          <fixr:component id="{$component-identifier(@name)}" name="{@name}">
            <xsl:for-each select="*">
              <xsl:choose>
                <xsl:when test="self::field">
                  <xsl:call-template name="field-ref">
                    <xsl:with-param name="field-name" select="@name"/>
                    <xsl:with-param name="required" select="@required"/>
                  </xsl:call-template>
                </xsl:when>

                <xsl:when test="self::component">
                  <xsl:call-template name="component-ref">
                    <xsl:with-param name="component-name" select="@name"/>
                    <xsl:with-param name="required" select="@required"/>
                  </xsl:call-template>
                  <xsl:call-template name="group-ref">
                    <xsl:with-param name="group-name" select="@name"/>
                    <xsl:with-param name="required" select="@required"/>
                  </xsl:call-template>
                </xsl:when>
              </xsl:choose>
            </xsl:for-each>
          </fixr:component>
        </xsl:for-each>

        <xsl:if test="exists(/fix/trailer/field)">
          <fixr:component id="{$component-identifier('StandardTrailer')}" name="StandardTrailer">
            <xsl:for-each select="/fix/trailer/field">
              <xsl:call-template name="field-ref">
                <xsl:with-param name="field-name" select="@name"/>
                <xsl:with-param name="required" select="@required"/>
              </xsl:call-template>
            </xsl:for-each>
          </fixr:component>
        </xsl:if>
      </fixr:components>

      <fixr:groups>
        <xsl:for-each select="/fix/components/component/group">
          <fixr:group id="{$group-identifier(../@name)}" name="{../@name}">
            <xsl:variable name="numField" select="/fix/fields/field[@name=current()/@name][1]"/>
            <xsl:if test="$numField">
              <fixr:numInGroup id="{$numField/@number}"/>
            </xsl:if>
            <xsl:for-each select="*">
              <xsl:choose>
                <xsl:when test="self::field">
                  <xsl:call-template name="field-ref">
                    <xsl:with-param name="field-name" select="@name"/>
                    <xsl:with-param name="required" select="@required"/>
                  </xsl:call-template>
                </xsl:when>

                <xsl:when test="self::component">
                  <xsl:call-template name="component-ref">
                    <xsl:with-param name="component-name" select="@name"/>
                    <xsl:with-param name="required" select="@required"/>
                  </xsl:call-template>
                  <xsl:call-template name="group-ref">
                    <xsl:with-param name="group-name" select="@name"/>
                    <xsl:with-param name="required" select="@required"/>
                  </xsl:call-template>
                </xsl:when>
              </xsl:choose>
            </xsl:for-each>
          </fixr:group>
        </xsl:for-each>
      </fixr:groups>

      <fixr:messages>
        <xsl:for-each select="/fix/messages/message">
          <fixr:message id="{$message-identifier(@name)}" name="{@name}" msgType="{@msgtype}">
            <fixr:structure>
              <fixr:componentRef id="{$component-identifier('StandardHeader')}" name="StandardHeader" presence="required"/>
              <xsl:for-each select="*">
                <xsl:choose>
                  <xsl:when test="self::field">
                    <xsl:call-template name="field-ref">
                      <xsl:with-param name="field-name" select="@name"/>
                      <xsl:with-param name="required" select="@required"/>
                    </xsl:call-template>
                  </xsl:when>

                  <xsl:when test="self::component">
                    <xsl:call-template name="component-ref">
                      <xsl:with-param name="component-name" select="@name"/>
                      <xsl:with-param name="required" select="@required"/>
                    </xsl:call-template>
                    <xsl:call-template name="group-ref">
                      <xsl:with-param name="group-name" select="@name"/>
                      <xsl:with-param name="required" select="@required"/>
                    </xsl:call-template>
                  </xsl:when>

                </xsl:choose>
              </xsl:for-each>
              <fixr:componentRef id="{$component-identifier('StandardTrailer')}" name="StandardTrailer" presence="required"/>
            </fixr:structure>
          </fixr:message>
        </xsl:for-each>
      </fixr:messages>
    </fixr:repository>
  </xsl:template>

  <xsl:template name="field-ref">
    <xsl:param name="field-name"/><xsl:param name="required"/>
    <xsl:variable name="f" select="key('field-by-name',$field-name)[1]"/>
    <xsl:if test="$f">
      <fixr:fieldRef id="{$f/@number}" name="{$field-name}">
        <xsl:if test="$required = 'Y'">
          <xsl:attribute name="presence">required</xsl:attribute>
        </xsl:if>
      </fixr:fieldRef>
    </xsl:if>
  </xsl:template>

  <!-- Names of component elements are added for convenience (supported by Orchestra v1.1) -->
  <xsl:template name="component-ref">
    <xsl:param name="component-name"/><xsl:param name="required"/>
    <xsl:variable name="c" select="key('component-by-name',$component-name)[1]"/>
    <xsl:if test="$c">
      <fixr:componentRef>
        <xsl:attribute name="id"><xsl:value-of select="$component-identifier($component-name)"/></xsl:attribute>
        <xsl:attribute name="name"><xsl:value-of select="$component-name"/></xsl:attribute>
        <xsl:if test="$required = 'Y'">
          <xsl:attribute name="presence">required</xsl:attribute>
        </xsl:if>
      </fixr:componentRef>
    </xsl:if>
  </xsl:template>

  <!-- Names of group elements are added for convenience (supported by Orchestra v1.1) -->
  <xsl:template name="group-ref">
    <xsl:param name="group-name"/><xsl:param name="required"/>
    <xsl:variable name="g" select="key('group-by-name',$group-name)[1]"/>
    <xsl:if test="$g">
      <fixr:groupRef>
        <xsl:attribute name="id"><xsl:value-of select="$group-identifier($group-name)"/></xsl:attribute>
        <xsl:attribute name="name"><xsl:value-of select="$group-name"/></xsl:attribute>
        <xsl:if test="$required = 'Y'">
          <xsl:attribute name="presence">required</xsl:attribute>
        </xsl:if>
      </fixr:groupRef>
    </xsl:if>
  </xsl:template>

  <xsl:template name="datatype-name">
    <xsl:param name="quickfix-type"/>
    <xsl:choose>
      <xsl:when test="$quickfix-type='STRING'">String</xsl:when>
      <xsl:when test="$quickfix-type='CHAR'">char</xsl:when>
      <xsl:when test="$quickfix-type='INT'">int</xsl:when>
      <xsl:when test="$quickfix-type='LENGTH'">Length</xsl:when>
      <xsl:when test="$quickfix-type='TAGNUM'">TagNum</xsl:when>
      <xsl:when test="$quickfix-type='SEQNUM'">SeqNum</xsl:when>
      <xsl:when test="$quickfix-type='NUMINGROUP'">NumInGroup</xsl:when>
      <xsl:when test="$quickfix-type='DAYOFMONTH'">DayOfMonth</xsl:when>
      <xsl:when test="$quickfix-type='MONTHYEAR'">MonthYear</xsl:when>
      <xsl:when test="$quickfix-type='UTCTIMESTAMP' or $quickfix-type='UTC_TIMESTAMP'">UTCTimestamp</xsl:when>
      <xsl:when test="$quickfix-type='TZTIMESTAMP'">TZTimestamp</xsl:when>
      <xsl:when test="$quickfix-type='TZTIMEONLY'">TZTimeOnly</xsl:when>
      <xsl:when test="$quickfix-type='UTCTIMEONLY'">UTCTimeOnly</xsl:when>
      <xsl:when test="$quickfix-type='UTCDATEONLY'">UTCDateOnly</xsl:when>
      <xsl:when test="$quickfix-type='LOCALMKTDATE'">LocalMktDate</xsl:when>
      <xsl:when test="$quickfix-type='FLOAT'">float</xsl:when>
      <xsl:when test="$quickfix-type='PRICE'">Price</xsl:when>
      <xsl:when test="$quickfix-type='PRICEOFFSET'">PriceOffset</xsl:when>
      <xsl:when test="$quickfix-type='QTY'">Qty</xsl:when>
      <xsl:when test="$quickfix-type='AMT'">Amt</xsl:when>
      <xsl:when test="$quickfix-type='BOOLEAN'">Boolean</xsl:when>
      <xsl:when test="$quickfix-type='LOCALMKTDATE'">LocalMktDate</xsl:when>
      <xsl:when test="$quickfix-type='UTCDATEONLY'">UTCDateOnly</xsl:when>
      <xsl:when test="$quickfix-type='UTCTIMEONLY'">UTCTimeOnly</xsl:when>
      <xsl:when test="$quickfix-type='PERCENTAGE'">Percentage</xsl:when>
      <xsl:when test="$quickfix-type='CURRENCY'">Currency</xsl:when>
      <xsl:when test="$quickfix-type='COUNTRY'">Currency</xsl:when>
      <xsl:when test="$quickfix-type='LANGUAGE'">Language</xsl:when>
      <xsl:when test="$quickfix-type='MULTIPLEVALUESTRING'">MultipleValueString</xsl:when>
      <xsl:when test="$quickfix-type='MULTIPLESTRINGVALUE'">MultipleStringValue</xsl:when>
      <xsl:when test="$quickfix-type='MULTIPLECHARVALUE'">MultipleCharValue</xsl:when>
      <xsl:when test="$quickfix-type='EXCHANGE'">Exchange</xsl:when>
      <xsl:when test="$quickfix-type='PATTERN'">Pattern</xsl:when>
      <xsl:when test="$quickfix-type='RESERVED100PLUS'">Reserved100Plus</xsl:when>
      <xsl:when test="$quickfix-type='RESERVED1000PLUS'">Reserved1000Plus</xsl:when>
      <xsl:when test="$quickfix-type='RESERVED4000PLUS'">Reserved4000Plus</xsl:when>
      <xsl:when test="$quickfix-type='TENOR'">Tenor</xsl:when>
      <xsl:when test="$quickfix-type='DATA'">data</xsl:when>
      <xsl:when test="$quickfix-type='XMLDATA'">XMLData</xsl:when>
      <xsl:otherwise><xsl:value-of select="$quickfix-type"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="datatype">
    <xsl:param name="quickfix-type"/>
    <xsl:variable name="name"><xsl:call-template name="datatype-name">
      <xsl:with-param name="quickfix-type" select="$quickfix-type"/>
    </xsl:call-template></xsl:variable>
    <fixr:datatype name="{$name}">
      <xsl:choose>
        <xsl:when test="$quickfix-type = ('LENGTH', 'TAGNUM', 'SEQNUM', 'NUMINGROUP', 'DAYOFMONTH')">
          <xsl:attribute name="baseType"><xsl:value-of select="'int'"/></xsl:attribute>
        </xsl:when>
        <xsl:when test="$quickfix-type = ('QTY', 'PRICE', 'PRICEOFFSET', 'AMT', 'PERCENTAGE')">
          <xsl:attribute name="baseType"><xsl:value-of select="'float'"/></xsl:attribute>
        </xsl:when>
        <xsl:when test="$quickfix-type = ('BOOLEAN')">
          <xsl:attribute name="baseType"><xsl:value-of select="'char'"/></xsl:attribute>
        </xsl:when>
        <xsl:when test="$quickfix-type = ('MULTIPLEVALUESTRING', 'MULTIPLESTRINGVALUE', 'MULTIPLECHARVALUE', 'COUNTRY', 'CURRENCY', 'LANGUAGE', 'EXCHANGE', 'XMLDATA', 'XID', 'XIDREF')">
          <xsl:attribute name="baseType"><xsl:value-of select="'String'"/></xsl:attribute>
        </xsl:when>
        <xsl:when test="$quickfix-type = ('TENOR', 'RESERVED100PLUS', 'RESERVED1000PLUS', 'RESERVED4000PLUS')">
          <xsl:attribute name="baseType"><xsl:value-of select="'Pattern'"/></xsl:attribute>
        </xsl:when>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="$quickfix-type = 'STRING'"> <fixr:mappedDatatype standard="XML" builtin="true" base="xs:string"/></xsl:when>
        <xsl:when test="$quickfix-type = 'LANGUAGE'"> <fixr:mappedDatatype standard="XML" builtin="true" base="xs:language"/></xsl:when>
        <xsl:when test="$quickfix-type = ('CHAR', 'EXCHANGE')"> <fixr:mappedDatatype standard="XML" builtin="false" base="xs:string"/></xsl:when>
        <xsl:when test="$quickfix-type = 'CURRENCY'"><fixr:mappedDatatype standard="XML" builtin="false" base="xs:string" pattern=".{3}"/></xsl:when>
        <xsl:when test="$quickfix-type = 'COUNTRY'"><fixr:mappedDatatype standard="XML" builtin="false" base="xs:string" pattern=".{2}"/></xsl:when>
        <xsl:when test="$quickfix-type = 'MONTHYEAR'"><fixr:mappedDatatype standard="XML" builtin="false" base="xs:string" pattern="\d{4}(0|1)\d([0-3wW]\d)?"/></xsl:when>
        <xsl:when test="$quickfix-type = 'MULTIPLEVALUESTRING'"><fixr:mappedDatatype standard="XML" builtin="false" base="xs:string" pattern=".+(\s.+)*"/></xsl:when>
        <xsl:when test="$quickfix-type = 'MULTIPLESTRINGVALUE'"><fixr:mappedDatatype standard="XML" builtin="false" base="xs:string" pattern=".+(\s.+)*"/></xsl:when>
        <xsl:when test="$quickfix-type = 'MULTIPLECHARVALUE'"><fixr:mappedDatatype standard="XML" builtin="false" base="xs:string" pattern="[A-Za-z0-9](\s[A-Za-z0-9])*"/></xsl:when>
        <xsl:when test="$quickfix-type = 'INT'"><fixr:mappedDatatype standard="XML" builtin="true" base="xs:integer"/></xsl:when>
        <xsl:when test="$quickfix-type = 'DAYOFMONTH'"><fixr:mappedDatatype standard="XML" builtin="false" base="xs:integer"/></xsl:when>
        <xsl:when test="$quickfix-type = ('LENGTH', 'TAGNUM')"><fixr:mappedDatatype standard="XML" builtin="false" base="xs:nonNegativeInteger"/></xsl:when>
        <xsl:when test="$quickfix-type = 'SEQNUM'"><fixr:mappedDatatype standard="XML" builtin="false" base="xs:positiveInteger"/></xsl:when>
        <xsl:when test="$quickfix-type = 'FLOAT'"><fixr:mappedDatatype standard="XML" builtin="true" base="xs:decimal"/></xsl:when>
        <xsl:when test="$quickfix-type = ('PRICE', 'PRICEOFFSET', 'QTY', 'AMT', 'PERCENTAGE')">
          <fixr:mappedDatatype standard="XML" builtin="false" base="xs:decimal"/>
        </xsl:when>
        <xsl:when test="$quickfix-type = 'BOOLEAN'"><fixr:mappedDatatype standard="XML" builtin="false" base="xs:boolean" pattern="[YN]{1}"/></xsl:when>
        <xsl:when test="$quickfix-type = ('UTCTIMESTAMP', 'UTC_TIMESTAMP')">
          <fixr:mappedDatatype standard="XML" builtin="false" base="xs:dateTime"/>
        </xsl:when>
        <xsl:when test="$quickfix-type = 'UTCTIMEONLY'"><fixr:mappedDatatype standard="XML" builtin="false" base="xs:time"/></xsl:when>
        <xsl:when test="$quickfix-type = ('UTCDATEONLY', 'LOCALMKTDATE')">
          <fixr:mappedDatatype standard="XML" builtin="false" base="xs:date"/>
        </xsl:when>
        <xsl:when test="$quickfix-type = 'TZTIMESTAMP'"><fixr:mappedDatatype standard="XML" builtin="true" base="xs:dateTime"/></xsl:when>
        <xsl:when test="$quickfix-type = 'TZTIMEONLY'"><fixr:mappedDatatype standard="XML" builtin="true" base="xs:time"/></xsl:when>
        <xsl:when test="$quickfix-type = 'DATA'"><fixr:mappedDatatype standard="XML" builtin="true" base="xs:base64Binary"/></xsl:when>
        <xsl:when test="$quickfix-type = 'TENOR'"><fixr:mappedDatatype standard="XML" builtin="false" base="xs:string" pattern="[DMWY](\d)+"/></xsl:when>
        <xsl:when test="$quickfix-type = 'RESERVED100PLUS'"><fixr:mappedDatatype standard="XML" builtin="false" base="xs:integer" minInclusive="100"/></xsl:when>
        <xsl:when test="$quickfix-type = 'RESERVED1000PLUS'"><fixr:mappedDatatype standard="XML" builtin="false" base="xs:integer" minInclusive="1000"/></xsl:when>
        <xsl:when test="$quickfix-type = 'RESERVED4000PLUS'"><fixr:mappedDatatype standard="XML" builtin="false" base="xs:integer" minInclusive="4000"/></xsl:when>
        <xsl:when test="$quickfix-type = 'XID'"> <fixr:mappedDatatype standard="XML" builtin="true" base="xs:ID"/></xsl:when>
        <xsl:when test="$quickfix-type = 'XIDREF'"> <fixr:mappedDatatype standard="XML" builtin="true" base="xs:IDREF"/></xsl:when>
      </xsl:choose>
    </fixr:datatype>
  </xsl:template>
</xsl:stylesheet>
