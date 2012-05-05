--------------------------------------------------------------------------------
-- Using walker functions

require('plxml')
require('test')

-- Example functions that modify the tree and return nothing

function deleteComment( node ) 
    local is = node['type']

    if( is == 'element' and #node['data'] ~= 0 )  then
        for k, v in pairs( node['data'] )  do
            if( v['type'] == 'comment' )  then
                table.remove( node['data'], k ) 
            end
        end
    end
end

function upperText( node ) 
    local is = node['type']

    if( is == 'text' )  then
        node['data'] = node['data']:upper( ) 
    end
end

function wrapBrown( node )
    local word = 'brown'

    local is = node['type']

    if( is == 'text' ) then
        local pos = string.find(node['data'], word)

        if(pos) then
            local before = node['data']:sub(1,pos-1)
            local after  = node['data']:sub(pos+word:len(),-1)

            -- Yes this is evil. We are modifying a node in 
            -- place but it seems to work

            node['type'] = 'root'
            node['data'] = {
                plxml.newtext( before ),
                plxml.newelement( 'b', {}, plxml.newtext( word ) ),
                plxml.newtext( after )
            }
        end
    end
end

-- Wrappers for the tests

function atest( source, expected, ... )
    if(expected == nil) then
        expected = source
    end

    -- In the before position

    local root = plxml.build( plxml.newroot( ), plxml.parseXMLString( source ) )
    for _, code in pairs{...} do
        plxml.walk( root, code )
    end
    local s = plxml.toString( plxml.walk( root, plxml.beforeXML, plxml.afterXML ) )
    test.assertEqual( s, expected )

    -- In the after position

    local root = plxml.build( plxml.newroot( ), plxml.parseXMLString( source ) )
    for _, code in pairs{...} do
        plxml.walk( root, nil, code )
    end
    local s = plxml.toString( plxml.walk( root, plxml.beforeXML, plxml.afterXML ) )
    test.assertEqual( s, expected )
end

function btest( source, expected, code )
    local root = plxml.build( plxml.newroot( ), plxml.parseXMLString( source ) )

    -- Note that to stop the walker recursing into the modified node we 
    -- have to make sure that this is handled in the after position

    plxml.walk( root, nil, code )

    local s = plxml.toString( plxml.walk( root, plxml.beforeXML, plxml.afterXML ) )
    test.assertEqual( s, expected )
end

-- Input is untransformed

atest(
    '<?xml version="1.0"?><doc><!-- test --><person><forename>fred</forename><br/>smith</person><green id="1"/></doc>'
)

-- Just checking that multiline strings work

atest(
    [[<?xml version="1.0"?>
<doc>
    <!-- test -->
    <person>
        <forename>fred</forename>
        <br/>
        smith
    </person>
    <green id="1"/>
</doc>]]
)

-- Remove the comments

atest( 
    '<?xml version="1.0"?><doc><!-- test --><person><forename>fred</forename><br/>smith</person><green id="1"/></doc>',
    '<?xml version="1.0"?><doc><person><forename>fred</forename><br/>smith</person><green id="1"/></doc>',
    deleteComment
)

-- Multiline again

atest( 
    [[<?xml version="1.0"?>
<doc><!-- test -->
    <person>
        <forename>fred</forename>
        <br/>
        smith
    </person>
    <green id="1"/>
</doc>]],
    [[<?xml version="1.0"?>
<doc>
    <person>
        <forename>fred</forename>
        <br/>
        smith
    </person>
    <green id="1"/>
</doc>]],
    deleteComment
)

-- Uppercase text nodes

atest( 
    '<?xml version="1.0"?><doc><!-- test --><person><forename>fred</forename><br/>smith</person><green id="1"/></doc>',
    '<?xml version="1.0"?><doc><!-- test --><person><forename>FRED</forename><br/>SMITH</person><green id="1"/></doc>',
    upperText
)

-- Combined

atest(
    '<?xml version="1.0"?><doc><!-- test --><person><forename>fred</forename><br/>smith</person><green id="1"/></doc>',
    '<?xml version="1.0"?><doc><person><forename>FRED</forename><br/>SMITH</person><green id="1"/></doc>',
    deleteComment,
    upperText
)

-- Change a text node into a group of nodes

btest(
    '<?xml version="1.0"?><doc><p>The quick fox</p><p>jumped over the</p><p>lazy brown dog</p></doc>',
    '<?xml version="1.0"?><doc><p>The quick fox</p><p>jumped over the</p><p>lazy <b>brown</b> dog</p></doc>',
    wrapBrown
)
