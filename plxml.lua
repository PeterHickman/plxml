------------------------------------------------------------------------------
-- Title:               plxml.lua
-- Description:         Pure Lua XML parser
-- Author:              Peter Hickman (peterhi@ntlworld.com)
-- Creation Date:       2007/12/14
-- Legal:               Copyright (C) 2007 Peter Hickman
--                      Under the terms of the MIT License
--                      http://www.opensource.org/licenses/mit-license.html
--------------------------------------------------------------------------------

-- Parse a well formed and valid XML string into a nested table structure

--------------------------------------------------------------------------------

local error = error
local ipairs = ipairs
local pairs = pairs
local string = string
local type = type

module('plxml')

--------------------------------------------------------------------------------
-- Parse the attributes from a string

local function parse_attributes( data )
    local key = ''
    local value = ''
    local string_char=''
    local mode = 'key'

    local attributes = {}

    for pos=1,data:len() do
        local char = data:sub(pos,pos)

        if(mode == 'value') then
            if(char == string_char) then
                -- We now have the value
                if(attributes[key]) then
                    error('Attribute key "' .. key .. '" already set prior to character ' .. pos)
                end
                attributes[key] = value
                value = ''
                key = ''
                string_char = ''
                mode = 'key'
            else
                value = value .. char
            end
        elseif(mode == 'equals') then
            -- The correct format is key="value" with the double quote
            -- but we will accept key='value' with single quotes
            if(char == '"' or char == "'") then
                string_char = char
                mode = 'value'
            else
                error('Expecting a " or \' after the = at character ' .. pos)
            end
        else
            if(char == ' ') then
                if(key ~= '') then
                    error('Unexpected space at character ' .. pos)
                end
            else
                if(char == '=') then
                    mode = 'equals'
                else
                    key = key .. char
                end
            end
        end
    end

    if(key ~= '') then
        error('Incomplete attributes')
    end

    return attributes
end

--------------------------------------------------------------------------------
-- Private methods that turn strings into type of nodes that we handle. If you
-- want to create new nodes you should use the new...() functions below

local function maketext( data )
    return newtext( data )
end

local function makecomment( data )
    -- Get everything between the '<!--' and the '-->'
    local text = data:sub(5,-4)
    return newcomment( text )
end

local function makepi( data )
    -- The first space should occur after the name
    local start = data:find(' ')
    -- The name is between the '<?' and the space
    local name = data:sub(3,start-1)
    -- The body is from the first space up to the '?>'
    local text = data:sub(start+1,-3)
    return newpi( name, text )
end

local function makedoctype( data )
    -- The data is between the '<!' and the final '>'
    local text = data:sub(3,-2)
    return newdoctype( text )
end

local function makeelement( data )
    local name = ''
    local attributes = {}

    local pos = data:find(' ')
    if(pos) then
        name = data:sub(2,pos - 1)
        if(data:sub(-2,-1) == '/>') then
            attributes = parse_attributes(data:sub(pos+1,-3))
        else
            attributes = parse_attributes(data:sub(pos+1,-2))
        end
    else
        if(data:sub(-2,-1) == '/>') then
            name = data:sub(2,-3)
        else
            name = data:sub(2,-2)
        end
    end

    return newelement( name, attributes )
end

local function makecdata( data )
    return newcdata( data:sub(10, -4))
end

--------------------------------------------------------------------------------
-- Constructors for the various types of nodes

function newroot(...) 
    local data = {}

    for _,v in ipairs{...} do
        data[#data+1] = v
    end

    return { type='root', data=data }
end

function newtext( text )
    return { type='text', data=text }
end

function newcomment( text )
    return { type='comment', data=text }
end

function newpi( name, text )
    return { type='pi', name=name, data=text }
end

function newdoctype( text )
    return { type='doctype', data=text }
end

function newelement( name, attributes, ... )
    local data = {}

    for _,v in ipairs{...} do
        data[#data+1] = v
    end

    return { type='element', name=name, attributes=attributes, data=data }
end

function newcdata( text )
    return { type='cdata', data=text }
end

--------------------------------------------------------------------------------
-- Simply check that opened ' and " are closed in the element attributes

local function balancedQuotes( data )
    local type = ''

    for p = 1,data:len() do
        local char = data:sub(p,p)
        if(type == '') then
            if(char == '"' or char == "'") then
                type = char
            end
        elseif(type == char) then
            type = ''
        end
    end

    return type == ''
end

local function isBalanced( data, type )
    if(balancedQuotes(data)) then
        return type
    else
        return 'unknown'
    end
end

--------------------------------------------------------------------------------
-- Work out which type of node this is

local function identify( data )
    if(data == '') then
        return 'empty'
    end

    if(data:sub(1,1) == '<') then
        if(data:sub(1,2) == '<?') then
            if(data:sub(-2,-1) == '?>') then
                return isBalanced(data, 'pi')
            else
                return 'unknown'
            end
        elseif(data:sub(1,4) == '<!--') then
            if(data:sub(-3,-1) == '-->') then
                return 'comment'
            else
                return 'unknown'
            end
        elseif(data:sub(1,9) == '<![CDATA[') then
            if(data:sub(-3,-1) == ']]>') then
                return 'cdata'
            else
                return 'unknown'
            end
        elseif(data:sub(1,2) == '<!') then
            if(data:sub(-1,-1) == '>') then
                return isBalanced(data, 'doctype')
            else
                return 'unknown'
            end
        elseif(data:sub(1,2) == '</') then
            if(data:sub(-1,-1) == '>') then
                return 'element-end'
            else
                return 'unknown'
            end
        elseif(data:sub(-2,-1) == '/>') then
            return 'element-closed'
        else
            return isBalanced(data, 'element-start')
        end
    else
        return 'text'
    end
end

--------------------------------------------------------------------------------
-- From a string of XML create an iterator that will spit out token from text
-- enclosed in '<' .. '>' or the text found between the '>' .. '<'.

function parseXMLString( data )
    local start = 1
    local is_string = true

    return function()
        for p = start,data:len() do
            local char = data:sub(p,p)

            if(is_string) then
                if(char == '<') then
                    is_string = false
                    local s = start
                    start = p
                    return data:sub(s,p-1)
                end
            else
                if(char == '>') then
                    local is = identify(data:sub(start,p))

                    if(is == 'unknown') then
                        -- The correct closing > is not yet reached
                    else
                        is_string = true
                        local s = start
                        start = p + 1
                        return data:sub(s,p)
                    end
                end
            end
        end

        -- There is a rare occasion where starting element attribute is missing
        -- it's closing ' or " and the rest of the line gets eaten up looking for
        -- it. So the loop ends without having returned all the data
        --
        -- The indication of this is start NOT being one greater than the length
        -- of the data.

        if(start <= data:len()) then
            return data:sub(start,-1)
        end
    end
end

--------------------------------------------------------------------------------
-- Use the iterator to build the document tree

function build( node, iter )
    for x in iter do
        local is = identify(x)
        local pos = #node['data'] + 1

        if(is == 'empty') then
            -- do nothing
        elseif(is == 'pi') then
            node['data'][pos] = makepi(x)
        elseif(is == 'comment') then
            node['data'][pos] = makecomment(x)
        elseif(is == 'cdata') then
            node['data'][pos] = makecdata(x)
        elseif(is == 'doctype') then
            node['data'][pos] = makedoctype(x)
        elseif(is == 'text') then
            node['data'][pos] = maketext(x)
        elseif(is == 'element-end') then
            return node
        elseif(is == 'element-closed') then
            node['data'][pos] = makeelement(x)
        elseif(is == 'element-start') then
            local x = makeelement(x)
            node['data'][pos] = build(x, iter)
        else
            -- Postmortem the error
            if(x:sub(1,2) ~= '<?' and x:sub(1,2) ~= '<!' and x:sub(1,2) ~= '</') then
                if(balancedQuotes(x)) then
                    error("Identified the type '" .. is .. "' but don't what to do with it")
                else
                    error('Incomplete attributes')
                end
            else
                error("Identified the type '" .. is .. "' but don't what to do with it")
            end
        end
    end
    
    return node
end

--------------------------------------------------------------------------------
-- Walk the document applying the supplied functions before and after processing
-- the nodes held within the 'data' table of the node (if it has one). If the 
-- functions return a value it is appended to the list.

function walk( node, before, after )
    local x = {}

    if(before ~= nil) then
        local n = before(node)
        if(n) then
            x[#x+1] = n
        end
    end

    if(type(node['data']) == 'table') then
        for k,v in pairs(node['data']) do
            local n = walk(v, before, after)
            if(n) then
                x[#x+1] = n
            end
        end
    end

    if(after ~= nil) then
        local n = after(node)
        if(n) then
            x[#x+1] = n
        end
    end

    return x
end

--------------------------------------------------------------------------------
-- Not strictly part of the parser these functions allow the table to be 
-- converted back into an XML text string when used with the walk() function

function beforeXML( node )
    local is = node['type']

    if(is == 'pi') then
        return '<?' .. node['name'] .. ' ' .. node['data'] .. '?>'
    elseif(is == 'comment') then
        return '<!--' .. node['data'] .. '-->'
    elseif(is == 'cdata') then
        return '<![CDATA[' .. node['data'] .. ']]>'
    elseif(is == 'doctype') then
        return '<!' .. node['data'] .. '>'
    elseif(is == 'text') then
        return node['data']
    elseif(is == 'element') then
        local text = '<' .. node['name']

        for k,v in pairs(node['attributes']) do
            -- The string we use depends on the data
            local delimiter = '"'
            if(string.find(v,'"')) then
                delimiter = "'"
            end
            text = text .. ' ' .. k .. '=' .. delimiter .. v .. delimiter
        end

        if(#node['data'] == 0) then
            text = text .. '/>'
        else
            text = text .. '>'
        end

        return text
    elseif(is == 'root') then
        -- Do nothing with this container
    else
        error("Processing a '" .. is .. "' node but don't know what to do with it")
    end
end

function afterXML( node )
    local is = node['type']

    if(is == 'element' and #node['data'] ~= 0) then
        return '</' .. node['name'] .. '>'
    end
end

--------------------------------------------------------------------------------
-- Like wise this is useful to convert the reconstituted XML back into a string

function toString( data )
    local text = ''

    for _, v in pairs(data) do
        if(type(v) == 'table') then
            text = text .. toString(v)
        else
            text = text .. v
        end
    end

    return text
end

--------------------------------------------------------------------------------
