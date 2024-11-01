uniform sampler2D _HexCellData;
uniform vec4 _HexCellData_TexelSize;

vec4 GetCellData (vec3 cell_indices, int index)
{
	//Convert the cell index to UV coordinates
	vec2 uv;
	
	uv.x = cell_indices[index] * _HexCellData_TexelSize.x;
	float row = floor(uv.x);
	uv.x -= row;
	
	uv.y = (row + 0.5) * _HexCellData_TexelSize.y;
	
	vec4 data = textureLod(_HexCellData, uv, 0.0);
	data.w *= 255.0;
	
	return data;
}
















