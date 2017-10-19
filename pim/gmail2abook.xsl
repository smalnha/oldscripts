<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="/">
      <xsl:for-each select="root/row">
<xsl:if test="contains(Group_Membership,'ARL') or contains(Family_Name,'Lam')">
# <xsl:value-of select="Name"/>
[<xsl:number value="position()"/>]
name=<xsl:value-of select="Name"/>
# <xsl:value-of select="Family_Name"/>, <xsl:value-of select="Given_Name"/> <xsl:value-of select="Additional_Name"/> <xsl:value-of select="Name_Suffix"/> 
nick=<xsl:value-of select="Nickname"/> 
email=<xsl:if test="not(contains(E_mail_1___Type,'Home'))"><xsl:value-of select="E_mail_1___Value"/>,</xsl:if><xsl:if test="not(contains(E_mail_2___Type,'Home'))"><xsl:value-of select="E_mail_2___Value"/>,</xsl:if><xsl:if test="not(contains(E_mail_3___Type,'Home'))"><xsl:value-of select="E_mail_3___Value"/></xsl:if>
address=<xsl:value-of select="Address_1___Street"/> 
city=<xsl:value-of select="Address_1___City"/> 
state=<xsl:value-of select="Address_1___Region"/> 
zip=<xsl:value-of select="Address_1___Postal_Code"/> 
country=<xsl:value-of select="Address_1___Country"/> 
phone=<xsl:value-of select="Phone_1___Value"/> 
workphone=<xsl:value-of select="Phone_2___Value"/> 
notes="<xsl:value-of select="translate(Address_1___Formatted,'&#10;','; ')"/>  <xsl:value-of select="Jot_1"/>  "
</xsl:if>
      </xsl:for-each>
</xsl:template>

</xsl:stylesheet>
<!--
    Birthday,Gender,Location,Billing Information,Directory Server,Mileage,Occupation,Hobby,Sensitivity,Priority,Subject,Notes
    ,Group Membership,E-mail 1 - Type,E-mail 1 - Value,E-mail 2 - Type,E-mail 2 - Value,E-mail 3 - Typ
    e,E-mail 3 - Value,E-mail 4 - Type,E-mail 4 - Value,IM 1 - Type,IM 1 - Service,IM 1 - Value,Phone 
    1 - Type,Phone 1 - Value,Phone 2 - Type,Phone 2 - Value,Phone 3 - Type,Phone 3 - Value,Phone 4 - T
    ype,Phone 4 - Value,Phone 5 - Type,Phone 5 - Value,
Address 1 - Type,
Address 2 - Type,Address 2 - Formatted,Address 2 - Street
    ,Address 2 - City,Address 2 - PO Box,Address 2 - Region,Address 2 - Postal Code,Address 2 - Countr
    y,Address 2 - Extended Address,Organization 1 - Type,Organization 1 - Name,Organization 1 - Yomi N
    ame,Organization 1 - Title,Organization 1 - Department,Organization 1 - Symbol,Organization 1 - Lo
    cation,Organization 1 - Job Description,Website 1 - Type,Website 1 - Value,Event 1 - Type,Event 1 
    - Value,Custom Field 1 - Type,Custom Field 1 - Value,Jot 1 - Type
-->
