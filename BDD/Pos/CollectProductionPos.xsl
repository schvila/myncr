<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:wi="http://schemas.microsoft.com/wix/2006/wi"
    xmlns:wix="http://schemas.microsoft.com/wix/2006/wi"
    xmlns:msxsl="urn:schemas-microsoft-com:xslt"
    xmlns:strfn="urn:string-functions"
    xmlns=""
    exclude-result-prefixes="wi">
    <xsl:output method="xml" encoding="utf-8" indent="yes" />

    <xsl:variable name="allWxsFiles" select="document('../../../Installation/RPOS/POS.wxs') | document('../../../Installation/RPOS/Forecourt.wxs') | document('../../../Brand/SOPUSVantage/Installation/RPOS/SOPUSVantage.wxs')" />

    <xsl:template match="/">
        <Files>
            <xsl:apply-templates select="//wix:Feature[@Id='RPOSFeatures']" />
        </Files>
    </xsl:template>
        
    <xsl:template match="wix:Feature[@Id='RPOSFeatures']">
        <xsl:apply-templates select="current()/wix:FeatureRef">
            <xsl:with-param name="folder">bin</xsl:with-param>
        </xsl:apply-templates>
    </xsl:template>
        
    <xsl:template match="wix:Feature">
        <xsl:param name="folder"/>
        <xsl:apply-templates select="wix:ComponentRef">
            <xsl:with-param name="folder"><xsl:value-of select="$folder"/></xsl:with-param>
        </xsl:apply-templates>
        <xsl:apply-templates select="current()/wix:Feature">
            <xsl:with-param name="folder"><xsl:value-of select="$folder"/></xsl:with-param>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="wix:FeatureRef">
        <xsl:param name="folder"/>
        <xsl:apply-templates select="$allWxsFiles//wix:Feature[@Id=current()/@Id]">
            <xsl:with-param name="folder"><xsl:value-of select="$folder"/></xsl:with-param>
        </xsl:apply-templates>
    </xsl:template>
        
    <xsl:template match="wix:ComponentRef">
        <xsl:param name="folder"/>
        <xsl:choose>
            <xsl:when test="$folder='bin'">
                <xsl:apply-templates select="($allWxsFiles//wix:Directory[@Id='NTx86'] | $allWxsFiles//wix:DirectoryRef[@Id='NTx86'])/wix:Component[@Id=current()/@Id]">
                    <xsl:with-param name="folder"><xsl:value-of select="$folder"/></xsl:with-param>
                </xsl:apply-templates>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="wix:Component">
        <xsl:param name="folder"/>
        <xsl:apply-templates select="wix:File">
            <xsl:with-param name="folder"><xsl:value-of select="$folder"/></xsl:with-param>
        </xsl:apply-templates>
        <xsl:apply-templates select="wix:CopyFile">
            <xsl:with-param name="folder"><xsl:value-of select="$folder"/></xsl:with-param>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="wix:Component/wix:CopyFile">
        <xsl:param name="folder"/>
        <xsl:apply-templates select="$allWxsFiles//wix:File[@Id=current()/@FileId]">
            <xsl:with-param name="folder"><xsl:value-of select="$folder"/></xsl:with-param>
        </xsl:apply-templates>
    </xsl:template>

   <msxsl:script language="CSharp" implements-prefix="strfn">
       public string ReplaceString(string text, string oldValue, string newValue)
       {
           return text.Replace(oldValue, newValue);
       }
   </msxsl:script>

    <!-- Skip customer-specific files. -->
    <xsl:template match="wix:File[not(contains(@Source, 'CustomerConfigurations'))]">
        <xsl:param name="folder"/>
        <File>
            <xsl:element name="Source">
                <xsl:value-of select="strfn:ReplaceString(string(current()/@Source),'$(var.','$(WixPath_')"/>
            </xsl:element>
            <xsl:element name="Dir">
                <xsl:value-of select="$folder"/>
            </xsl:element>
            <xsl:element name="Name">
                <xsl:value-of select="current()/@Name"/>
            </xsl:element>
        </File>
    </xsl:template>

    <xsl:template match="node() | @*">
        <xsl:apply-templates select="node() | @*"/>
    </xsl:template>

</xsl:stylesheet>
