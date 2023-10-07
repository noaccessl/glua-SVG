# glua-SVG
Allows you to load and render SVGs in GMod
### Example
![image](https://user-images.githubusercontent.com/54954576/273377886-c631becc-2c80-401c-bf18-1155794c96ac.png)
```lua
local w, h = 120, 120

svg.Test = svg.Generate( 'ok', w, h, [[<svg xmlns="http://www.w3.org/2000/svg" x="0px" y="0px" width="240" height="240" viewBox="0 0 48 48">
<path fill="#4caf50" d="M44,24c0,11.045-8.955,20-20,20S4,35.045,4,24S12.955,4,24,4S44,12.955,44,24z"></path><path fill="#ccff90" d="M34.602,14.602L21,28.199l-5.602-5.598l-2.797,2.797L21,33.801l16.398-16.402L34.602,14.602z"></path>
</svg>]] )

hook.Add( 'HUDPaint', '', function()
	svg.Test( ScrW() * 0.5 - w * 0.5, ScrH() * 0.5 - h * 0.5 )
end )
```
![image](https://user-images.githubusercontent.com/54954576/273383571-df67cae0-f0c6-4e22-8193-dde0df1958a8.png)

```lua
local w, h = 144, 144

svg.Test = svg.LoadURL( 'gmod', w, h, 'https://upload.wikimedia.org/wikipedia/commons/9/97/Garry%27s_Mod_logo.svg' )

hook.Add( 'HUDPaint', '', function()
	svg.Test( ScrW() * 0.5 - w * 0.5, ScrH() * 0.5 - h * 0.5 )
end )
```
