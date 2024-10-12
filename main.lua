--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Prepare
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
--
-- Metamethods: Panel
--
local RemoveHandle = FindMetaTable( 'Panel' ).Remove

--
-- Globals, Utilities
--
local Assert	= assert
local isnumber	= isnumber
local isstring	= isstring

local strfind	= string.find
local substrof	= string.sub
local strgsub	= string.gsub

local Format	= string.format

local strfill do

	local strlen = string.len

	function strfill( str, what, pos, needed )

		if ( not strfind( str, what ) ) then
			return substrof( str, 1, pos ) .. needed .. substrof( str, pos + strlen( needed ) )
		end

		return str

	end

end

--
-- HTML wrap for SVGs
--
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

	GamemodeLoaded = false

}

local Registry = {}
local Queue = util.Stack()

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	GetRegistry
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
function svg.GetRegistry()

	return Registry

end


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	CreateOrUpdateSVGHandle
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local function CreateOrUpdateSVGHandle( id, w, h, strSVG )

	local pHandle = Registry[ id ]

	if ( not pHandle ) then

		pHandle = vgui.Create( 'DHTML' )
		pHandle:SetVisible( false )

		Registry[ id ] = pHandle

	end

	pHandle:SetSize( w, h )
	pHandle:SetHTML( Format( SVG_TEMPLATE, strSVG ) )

end

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	NewQueuedSVG
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local CQueuedSVG = {}
do

	CQueuedSVG.__index = CQueuedSVG

	function CQueuedSVG:Init( id, w, h, strSVG )

		self.ID = id
		self.w = w
		self.h = h
		self.SVG = strSVG

	end

	function CQueuedSVG:Unpack()

		return self.ID, self.w, self.h, self.SVG

	end

end

local function NewQueuedSVG( id, w, h, strSVG )

	local pQueuedSVG = {}
	setmetatable( pQueuedSVG, CQueuedSVG )

	pQueuedSVG:Init( id, w, h, strSVG )

	return pQueuedSVG

end

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Generate
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
function svg.Generate( id, w, h, strSVG )

	--
	-- Pinch of assertions
	--
	Assert( isnumber( w ), 'invalid width' )
	Assert( isnumber( h ), 'invalid height' )

	Assert( isstring( strSVG ), 'invalid svg' )

	local open		= strfind( strSVG, '<svg%s(.-)>' )
	local _, close	= strfind( strSVG, '</svg>%s*$' )

	Assert( ( open and close ) ~= nil, 'invalid svg' )

	--
	-- Adjust
	--
	strSVG = substrof( strSVG, open, close )

	strSVG = strfill( strSVG, 'width="(.-)"', 5, 'width="" ' )
	strSVG = strfill( strSVG, 'height="(.-)"', 5, 'height="" ' )

	strSVG = strgsub( strSVG, 'width="(.-)"', 'width="' .. w .. '"' )
	strSVG = strgsub( strSVG, 'height="(.-)"', 'height="' .. h .. '"' )

	--
	-- Generate
	--
	if ( svg.GamemodeLoaded ) then
		CreateOrUpdateSVGHandle( id, w, h, strSVG )
	else

		local pQueuedSVG = NewQueuedSVG( id, w, h, strSVG )
		Queue:Push( pQueuedSVG )

	end

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

	return function( ... )

		svg.Draw( id, ... )

	end

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
		If set to true, it will create material with color support for SVG.
		It's not that expensive and if you don't need color support just omit this argument.

	@r, g, b, a:
		Same principle as with surface.SetDrawColor
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local Draw do

	--
	-- Metatables
	--
	local Panel		= FindMetaTable( 'Panel' )
	local IMaterial	= FindMetaTable( 'IMaterial' )

	--
	-- Metamethods: Panel, IMaterial
	--
	local UpdateHTMLTexture	= Panel.UpdateHTMLTexture
	local GetHTMLMaterial	= Panel.GetHTMLMaterial

	local WidthOf	= IMaterial.Width
	local HeightOf	= IMaterial.Height
	local NameOf	= IMaterial.GetName

	--
	-- Utilities, Globals
	--
	local SetupMaterial do

		local MatParameters_t = {

			[ '$translucent' ] = 1;
			[ '$vertexalpha' ] = 1;
			[ '$vertexcolor' ] = 1

		}

		local strmatch		 = string.match
		local CreateMaterial = CreateMaterial

		function SetupMaterial( id, name, w, h )

			MatParameters_t[ '$basetexture' ] = name

			local UniqueName = Format( '%s_%s_%d_%d', id, strmatch( name, '%d+' ), w, h )

			return CreateMaterial(

				UniqueName,
				'UnlitGeneric',
				MatParameters_t

			)

		end

	end

	local SetDrawColor		= surface.SetDrawColor
	local SetMaterial		= surface.SetMaterial
	local DrawTexturedRect	= surface.DrawTexturedRect

	local IsColor = IsColor

	function Draw( id, x, y, color, r, g, b, a )

		--
		-- Retrieve the handle
		--
		local pHandle = Registry[ id ]

		if ( not pHandle ) then
			return
		end

		--
		-- Prepare the material
		--
		UpdateHTMLTexture( pHandle )

		local pMaterial = GetHTMLMaterial( pHandle )

		if ( not pMaterial ) then
			return
		end

		local w = WidthOf( pMaterial )
		local h = HeightOf( pMaterial )

		--
		-- Manage the color
		--
		if ( color == true ) then

			pMaterial = SetupMaterial( id, NameOf( pMaterial ), w, h )

			if ( IsColor( r ) ) then

				color = r
				SetDrawColor( color.r, color.g, color.b, color.a )

			else
				SetDrawColor( r, g, b, a )
			end

		else
			SetDrawColor( 255, 255, 255 )
		end

		--
		-- Draw
		--
		SetMaterial( pMaterial )
		DrawTexturedRect( x, y, w, h )

	end

end

function svg.Draw( id, x, y, color, r, g, b, a )

	Draw( id, x, y, color, r, g, b, a )

end


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	PurgeAll
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
function svg.PurgeAll()

	local Registry = Registry

	for id, pHandle in pairs( Registry ) do

		RemoveHandle( pHandle )
		Registry[ id ] = nil

	end

end

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Unload
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
function svg.Unload( id )

	local Registry = Registry
	local pHandle = Registry[ id ]

	if ( pHandle ) then

		RemoveHandle( pHandle )
		Registry[ id ] = nil

	end

end


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Queue for pre-generating SVGs on startup
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
hook.Add( 'OnGamemodeLoaded', 'PregenerateSVG', function()

	svg.GamemodeLoaded = true

	if ( Queue:Size() == 0 ) then

		Queue = nil
		return

	end

	::ProcessQueue::

		local pQueuedSVG = Queue:Pop()

		CreateOrUpdateSVGHandle( pQueuedSVG:Unpack() )
		pQueuedSVG = nil

	if ( Queue:Size() > 0 ) then
		goto ProcessQueue
	end

	Queue = nil

end )
