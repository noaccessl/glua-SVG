--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Prepare
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local RemoveHandle = FindMetaTable( 'Panel' ).Remove

local Assert	= assert
local isnumber	= isnumber
local isstring	= isstring

local strfind	= string.find
local substrof	= string.sub
local strgsub	= string.gsub

local Format	= string.format

-- Helper function
local SetIfEmpty do

	local strlen = string.len

	function SetIfEmpty( str, what, pos, needed )

		if not strfind( str, what ) then
			return substrof( str, 1, pos ) .. needed .. substrof( str, pos + strlen( needed ) )
		end

		return str

	end

end

-- HTML wrap for SVGs
local SVG_TEMPLATE = [[
	<html>
		<head>
			<style>
				body {
					margin: 0;
					padding: 0;
					overflow: hidden;
				}
			</style>
		</head>
		<body>
			%s
		</body>
	</html>
]]


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Initialize
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
svg = svg or {

	Registry = {}

}

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	PurgeAll
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
function svg.PurgeAll()

	local Registry = svg.Registry

	for id, pHandle in pairs( Registry ) do

		RemoveHandle( pHandle )
		Registry[ id ] = nil

	end

end

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Unload
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
function svg.Unload( id )

	local Registry = svg.Registry
	local pHandle = Registry[ id ]

	if pHandle then

		RemoveHandle( pHandle )
		Registry[ id ] = nil

	end

end

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Generate
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
function svg.Generate( id, w, h, strSVG )

	-- Pinch of asserts
	Assert( isnumber( w ), 'invalid width' )
	Assert( isnumber( h ), 'invalid height' )

	Assert( isstring( strSVG ), 'invalid svg' )

	local open		= strfind( strSVG, '<svg%s(.-)>' )
	local _, close	= strfind( strSVG, '</svg>%s*$' )

	Assert( ( open and close ) ~= nil, 'invalid svg' )

	-- Corrections
	strSVG = substrof( strSVG, open, close )

	strSVG = SetIfEmpty( strSVG, 'width="(.-)"', 5, 'width="" ' )
	strSVG = SetIfEmpty( strSVG, 'height="(.-)"', 5, 'height="" ' )

	strSVG = strgsub( strSVG, 'width="(.-)"', 'width="' .. w .. '"' )
	strSVG = strgsub( strSVG, 'height="(.-)"', 'height="' .. h .. '"' )

	-- Cooking
	local Registry = svg.Registry
	local pHandle = Registry[ id ]

	if not pHandle then

		pHandle = vgui.Create( 'DHTML' )
		pHandle:SetVisible( false )

		Registry[ id ] = pHandle

	end

	pHandle:SetSize( w, h )
	pHandle:SetHTML( Format( SVG_TEMPLATE, strSVG ) )

	return function( ... )

		svg.Draw( id, ... )

	end

end

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Load
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
function svg.Load( id, w, h, path )

	local strSVG = file.Read( path, 'DATA' )
	Assert( strSVG ~= nil, 'invalid path' )

	return svg.Generate( id, w, h, strSVG )

end

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	AsyncLoad
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
function svg.AsyncLoad( id, w, h, path )

	file.AsyncRead( path, 'DATA', function( _, _, status, strSVG )

		Assert( status == FSASYNC_OK, Format( 'Something went wrong. Status: %i', status ) )
		svg.Generate( id, w, h, strSVG )

	end )

end

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	LoadURL
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
function svg.LoadURL( id, w, h, url )

	Assert( string.GetExtensionFromFilename( url ) == 'svg', 'invalid svg' )

	http.Fetch( url, function( strSVG )

		svg.Generate( id, w, h, strSVG )

	end, function( err )

		error( err )
		svg.Unload( id )

	end )

	return function( ... )

		svg.Draw( id, ... )

	end

end

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Draw

	@color:
		If set to true, it will create material with color support.
		It's not that expensive and if you don't need color support just omit this argument.

	@r, g, b, a:
		Same principle as with surface.SetDrawColor
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
do

	local PANEL				= FindMetaTable( 'Panel' )
	local IMATERIAL			= FindMetaTable( 'IMaterial' )

	local UpdateHTMLTexture	= PANEL.UpdateHTMLTexture
	local GetHTMLMaterial	= PANEL.GetHTMLMaterial

	local SetDrawColor		= surface.SetDrawColor
	local SetMaterial		= surface.SetMaterial
	local DrawTexturedRect	= surface.DrawTexturedRect

	local WidthOf			= IMATERIAL.Width
	local HeightOf			= IMATERIAL.Height
	local NameOf			= IMATERIAL.GetName

	local CreateMaterial	= CreateMaterial

	local strmatch			= string.match

	local Attributes = {

		[ '$translucent' ] = 1;
		[ '$vertexalpha' ] = 1;
		[ '$vertexcolor' ] = 1

	}

	local function SetupMaterial( id, name, w, h )

		Attributes[ '$basetexture' ] = name

		local UniqueName = Format( '%s_%s_%d_%d', id, strmatch( name, '%d+' ), w, h )
		return CreateMaterial( UniqueName, 'UnlitGeneric', Attributes )

	end

	local IsColor = IsColor

	function svg.Draw( id, x, y, color, r, g, b, a )

		local pHandle = svg.Registry[ id ]

		if not pHandle then
			return
		end

		UpdateHTMLTexture( pHandle )

		local pMaterial = GetHTMLMaterial( pHandle )

		if not pMaterial then
			return
		end

		local w = WidthOf( pMaterial )
		local h = HeightOf( pMaterial )

		if color == true then

			pMaterial = SetupMaterial( id, NameOf( pMaterial ), w, h )

			if IsColor( r ) then
				SetDrawColor( r.r, r.g, r.b, r.a )
			else
				SetDrawColor( r, g, b, a )
			end

		else
			SetDrawColor( 255, 255, 255 )
		end

		SetMaterial( pMaterial )
		DrawTexturedRect( x, y, w, h )

	end

end
