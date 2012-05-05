--------------------------------------------------------------------------------
-- Can we handle CDATA

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

-- Safe CDATA, no >

local source = '<![CDATA[ function matchwo(a,b) { if (a < b && a < 0) then { return 1; } else { return 0; } } ]]>'
atest( source, 'cdata' )

-- Unsafe CDATA

local source = '<![CDATA[ function matchwo(a,b) { if (b > a && 0 > a) then { return 1; } else { return 0; } } ]]>'
atest( source, 'cdata' )

-- Similar issues with comments

local source = '<!-- > -->'
atest( source, 'comment' )

local source = '<!-- -> -->'
atest( source, 'comment' )

local source = '<!-- ->-->'
atest( source, 'comment' )
