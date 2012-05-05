--------------------------------------------------------------------------------
-- Edge cases from the coverage

require('plxml')
require('test')

-- It is possible to create some bad nodes

local root = plxml.newroot(
    plxml.newelement('doc', 
        plxml.newtext( 'this is the text '),
        { type='text', data='This is also text' },
        { type='junk' }
    )
)

local code = function () return plxml.toString( plxml.walk( root, plxml.beforeXML, plxml.afterXML ) ) end
local expected = "Processing a 'junk' node but don't know what to do with it"
test.assertThrowsError( code, expected )
