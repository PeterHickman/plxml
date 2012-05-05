--------------------------------------------------------------------------------
-- There are various errors that can occur when parsing arributes

require('plxml')
require('test')

function nodetype( root )
    local type = ''

    for _, v in pairs( root['data'] ) do
        type = v['type']
    end

    return type
end

function atest( source, thetype, expected )
    if( expected == nil ) then
        expected = source
    end

    local root = plxml.build( plxml.newroot( ), plxml.parseXMLString( source ) ) 
    test.assertEqual( nodetype( root ) , thetype )
    local text = plxml.toString( plxml.walk( root, plxml.beforeXML, plxml.afterXML ) )
    test.assertEqual( text, expected )

    -- What we have created should be safe

    local new_root = plxml.build( plxml.newroot( ), plxml.parseXMLString( text ) )
    test.assertEqual( nodetype( new_root ) , thetype )
    local new_text = plxml.toString( plxml.walk( root, plxml.beforeXML, plxml.afterXML ) )
    test.assertEqual( new_text, text )
end

function ftest( source, expected )
    local code = function () plxml.build( plxml.newroot( ), plxml.parseXMLString( source ) ) end
    test.assertThrowsError( code, expected )
end

-- Can use either ' or "

atest( '<doc a="1"/>', 'element' )
atest( "<doc a='1'/>", 'element', '<doc a="1"/>' )

-- Depending on the data

atest( '<doc a="this is \'quoted\' text"/>', 'element' )
atest( "<doc a='this is \"quoted\" text'/>", 'element' )

-- This should fail

ftest( '<doc a=1/>',            'Expecting a " or \' after the = at character 3' )
ftest( '<doc a="fred/>',        'Incomplete attributes' )
ftest( '<doc a="/>',            'Incomplete attributes' )
ftest( '<doc a=/>',             'Incomplete attributes' )
ftest( '<doc a/>',              'Incomplete attributes' )
ftest( '<doc dummy a="fred"/>', 'Unexpected space at character 6' )
ftest( '<doc a="1" a="2"/>',    'Attribute key "a" already set prior to character 11' )
ftest( '<!DOCTYPE wibble',      "Identified the type 'unknown' but don't what to do with it")
ftest( '</wibble',              "Identified the type 'unknown' but don't what to do with it")

-- Make sure the type of element makes no odds

ftest( '<doc a=1>Text</doc>',            'Expecting a " or \' after the = at character 3' )
ftest( '<doc a="fred>Text</doc>',        'Incomplete attributes' )
ftest( '<doc a=">Text</doc>',            'Incomplete attributes' )
ftest( '<doc a=>Text</doc>',             'Incomplete attributes' )
ftest( '<doc a>Text</doc>',              'Incomplete attributes' )
ftest( '<doc dummy a="fred">Text</doc>', 'Unexpected space at character 6' )
ftest( '<doc a="1" a="2">Text</doc>',    'Attribute key "a" already set prior to character 11' )

-- These are actualy valid

atest( '<doc a="fred>"/>',           'element' )
atest( '<?wibble bob="fred>fred"?>', 'pi')
atest( '<!wibble bob="fred>fred">',  'doctype')
