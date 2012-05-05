--------------------------------------------------------------------------------
-- Build the tree from nodes and convert it back into an xml string

require('plxml')
require('test')

-- First the plain nodes

local root = plxml.newtext('Hello World')
local source = plxml.toString( plxml.walk( root, plxml.beforeXML, plxml.afterXML ) )
test.assertEqual( source, 'Hello World' )

local root = plxml.newcomment('Hello World')
local source = plxml.toString( plxml.walk( root, plxml.beforeXML, plxml.afterXML ) )
test.assertEqual( source, '<!--Hello World-->' )

local root = plxml.newpi('xmltex', 'something')
local source = plxml.toString( plxml.walk( root, plxml.beforeXML, plxml.afterXML ) )
test.assertEqual( source, '<?xmltex something?>' )

local root = plxml.newdoctype( 'DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN"')
local source = plxml.toString( plxml.walk( root, plxml.beforeXML, plxml.afterXML ) )
test.assertEqual( source, '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN">' )

local root = plxml.newcdata( 'blah <blah> blah' )
local source = plxml.toString( plxml.walk( root, plxml.beforeXML, plxml.afterXML ) )
test.assertEqual( source, '<![CDATA[blah <blah> blah]]>' )

-- Wrapped in a root element

local root = plxml.newroot( plxml.newtext('Hello World') )
local source = plxml.toString( plxml.walk( root, plxml.beforeXML, plxml.afterXML ) )
test.assertEqual( source, 'Hello World')

local root = plxml.newroot( plxml.newcomment('Hello World') )
local source = plxml.toString( plxml.walk( root, plxml.beforeXML, plxml.afterXML ) )
test.assertEqual( source, '<!--Hello World-->' )

local root = plxml.newroot( plxml.newpi('xmltex', 'something') )
local source = plxml.toString( plxml.walk( root, plxml.beforeXML, plxml.afterXML ) )
test.assertEqual( source, '<?xmltex something?>' )

local root = plxml.newroot( plxml.newdoctype( 'DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN"') )
local source = plxml.toString( plxml.walk( root, plxml.beforeXML, plxml.afterXML ) )
test.assertEqual( source, '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN">' )

local root = plxml.newroot( plxml.newcdata( 'blah <blah> blah' ) )
local source = plxml.toString( plxml.walk( root, plxml.beforeXML, plxml.afterXML ) )
test.assertEqual( source, '<![CDATA[blah <blah> blah]]>' )

-- A newelement without contents

local root = plxml.newelement( 'p', {} )
local source = plxml.toString( plxml.walk( root, plxml.beforeXML, plxml.afterXML ) )
test.assertEqual( source, '<p/>' )

local root = plxml.newelement( 'p', { a=1 } )
local source = plxml.toString( plxml.walk( root, plxml.beforeXML, plxml.afterXML ) )
test.assertEqual( source, '<p a="1"/>' )

local root = plxml.newelement( 'p', { a=1, b=2 } )
local source = plxml.toString( plxml.walk( root, plxml.beforeXML, plxml.afterXML ) )
test.assertEqual( source, '<p a="1" b="2"/>' )

local root = plxml.newelement( 'p', { b=1, a=2 } )
local source = plxml.toString( plxml.walk( root, plxml.beforeXML, plxml.afterXML ) )
test.assertEqual( source, '<p a="2" b="1"/>' )

local root = plxml.newelement( 'p', { class='hot' } )
local source = plxml.toString( plxml.walk( root, plxml.beforeXML, plxml.afterXML ) )
test.assertEqual( source, '<p class="hot"/>' )

local root = plxml.newelement( 'p', { class='hot stuff' } )
local source = plxml.toString( plxml.walk( root, plxml.beforeXML, plxml.afterXML ) )
test.assertEqual( source, '<p class="hot stuff"/>' )

local root = plxml.newroot( plxml.newelement( 'p', { b=1, a=2 } ) )
local source = plxml.toString( plxml.walk( root, plxml.beforeXML, plxml.afterXML ) )
test.assertEqual( source, '<p a="2" b="1"/>' )

-- A newelement with contents

local root = plxml.newelement( 'p', {}, plxml.newtext('Hello World') )
local source = plxml.toString( plxml.walk( root, plxml.beforeXML, plxml.afterXML ) )
test.assertEqual( source, '<p>Hello World</p>' )

local root = plxml.newelement( 'p', { id=42 }, plxml.newtext('Hello World') )
local source = plxml.toString( plxml.walk( root, plxml.beforeXML, plxml.afterXML ) )
test.assertEqual( source, '<p id="42">Hello World</p>' )

local root = plxml.newelement( 'p', {}, plxml.newtext('Hello'), plxml.newtext(' '), plxml.newtext('World') )
local source = plxml.toString( plxml.walk( root, plxml.beforeXML, plxml.afterXML ) )
test.assertEqual( source, '<p>Hello World</p>' )
