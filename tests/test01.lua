--------------------------------------------------------------------------------
-- Roundtrip the xml, what goes in should come out

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
    local new_text = plxml.toString( plxml.walk( new_root, plxml.beforeXML, plxml.afterXML ) )
    test.assertEqual( new_text, text )
end

-- No attributes, space between name and /> are lost

atest( '<doc/>',     'element' )
atest( '<doc />',    'element', '<doc/>' )
atest( '<doc    />', 'element', '<doc/>' )

-- Attributes, spaces inside an element are lost

atest( '<doc a="1"/>',  'element' )
atest( '<doc a="1" />', 'element', '<doc a="1"/>' )
atest( '<doc  a="1"/>', 'element', '<doc a="1"/>' )

-- Attributes order is not preserved

atest( '<doc a="1" b="2"/>',         'element' )
atest( '<doc b="1" a="2"/>',         'element', '<doc a="2" b="1"/>')
atest( '<doc   b="1"    a="2"   />', 'element', '<doc a="2" b="1"/>')

-- Container elements, spare spaces are lost

atest( '<doc>Text</doc>',   'element' )
atest( '<doc >Text</doc>',  'element', '<doc>Text</doc>')
atest( '<doc>Text</ doc>',  'element', '<doc>Text</doc>')
atest( '<doc >Text</ doc>', 'element', '<doc>Text</doc>')

-- Spaces within the text are preserved

atest( '<doc>First<br/>Second</doc>',          'element' )
atest( '<doc> First <br/> Second   </doc>',    'element' )
atest( '<doc > First <br /> Second   </ doc>', 'element', '<doc> First <br/> Second   </doc>')

-- Comments could be a problem

atest( '<!--  -->', 'comment' )
atest( '<!-- -->',  'comment' )
atest( '<!---->',   'comment' )

-- Doctypes

atest('<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN">', 'doctype')
