--[[---------------------------------------------------------------------------
	Predefines
---------------------------------------------------------------------------]]
svg = svg or {}
svg.cache = svg.cache or {}

--[[---------------------------------------------------------------------------
	Template
---------------------------------------------------------------------------]]
local SVGTemplate = [[
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


function svg.ClearCache()

	for id, handle in pairs( svg.cache ) do

		handle:Remove()
		svg.cache[id] = nil

	end

end

function svg.Unload( id )

	if svg.cache[id] then

		svg.cache[id]:Remove()
		svg.cache[id] = nil

	end

end

--[[---------------------------------------------------------------------------
	Generate
---------------------------------------------------------------------------]]
function svg.Generate( id, w, h, strSVG )

	assert( isnumber( w ), 'invalid width' )
	assert( isnumber( h ), 'invalid height' )

	assert( isstring( strSVG ), 'invalid svg' )

	local open = string.find( strSVG, '<svg%s' )
	local _, close = string.find( strSVG, '</svg>%s*$' )

	assert( ( open and close ) ~= nil, 'invalid svg' )

	strSVG = string.sub( strSVG, open, close )

	strSVG = string.gsub( strSVG, 'width="[^"]+"', 'width="auto"' )
	strSVG = string.gsub( strSVG, 'height="[^"]+"', 'height="auto"' )

	local handle = svg.cache[id]

	if not handle then

		handle = vgui.Create( 'DHTML' )
		handle:SetVisible( false )

		svg.cache[id] = handle

	end

	handle:SetSize( w, h )
	handle:SetHTML( SVGTemplate:format( strSVG ) )

	return function( x, y, color )
		svg.Draw( id, x, y, color )
	end

end


--[[---------------------------------------------------------------------------
	Load
---------------------------------------------------------------------------]]
function svg.Load( id, w, h, path )

	local strSVG = file.Read( path, 'DATA' )
	assert( strSVG ~= nil, 'invalid path' )

	return svg.Generate( id, w, h, strSVG )

end

function svg.LoadURL( id, w, h, url )

	assert( string.GetExtensionFromFilename( url ) == 'svg', 'invalid svg' )

	local handle = svg.cache[id]

	if not handle then

		handle = vgui.Create( 'DHTML' )
		handle:SetVisible( false )

		svg.cache[id] = handle

	end

	handle:SetSize( w, h )
	handle:OpenURL( url )

	return function( x, y, color )
		svg.Draw( id, x, y, color )
	end

end


--[[---------------------------------------------------------------------------
	Draw
---------------------------------------------------------------------------]]
do

	local _R = debug.getregistry()

	local UpdateHTMLTexture = _R.Panel.UpdateHTMLTexture
	local GetHTMLMaterial = _R.Panel.GetHTMLMaterial

	local SetDrawColor = surface.SetDrawColor
	local SetMaterial = surface.SetMaterial
	local DrawTexturedRect = surface.DrawTexturedRect

	local MaterialWidth = _R.IMaterial.Width
	local MaterialHeight = _R.IMaterial.Height

	function svg.Draw( id, x, y, color )

		local handle = svg.cache[id]

		if not handle then
			return
		end

		UpdateHTMLTexture( handle )

		local mat = GetHTMLMaterial( handle )

		if not mat then
			return
		end

		if color then
			SetDrawColor( color )
		else
			SetDrawColor( 255, 255, 255 )
		end

		SetMaterial( mat )
		DrawTexturedRect( x, y, MaterialWidth( mat ), MaterialHeight( mat ) )

	end

end
