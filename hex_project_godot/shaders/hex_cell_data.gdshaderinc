global uniform sampler2D _HexCellData;
global uniform vec4 _HexCellData_TexelSize;
global uniform bool HEX_MAP_EDIT_MODE;

vec4 FilterCellData (vec4 data)
{
	//Check to see if we are in edit mode
	if (HEX_MAP_EDIT_MODE)
	{
		//If so, set the "x" value (the visibility value) to be 1
		data.x = 1.0;
		data.y = 1.0;
	}
	
	return data;
}

vec4 GetCellData (vec3 cell_indices, int index)
{
	//Convert the cell index to UV coordinates
	vec2 uv;
	
	uv.x = (cell_indices[index] + 0.5) * _HexCellData_TexelSize.x;
	float row = floor(uv.x);
	uv.x -= row;
	
	uv.y = (row + 0.5) * _HexCellData_TexelSize.y;
	
	vec4 data = textureLod(_HexCellData, uv, 0.0);
	return FilterCellData(data);
}

vec4 GetCellData_FromFloatIndex (float cell_index)
{
	//Convert the cell index to UV coordinates
	vec2 uv;
	
	uv.x = (cell_index + 0.5) * _HexCellData_TexelSize.x;
	float row = floor(uv.x);
	uv.x -= row;
	
	uv.y = (row + 0.5) * _HexCellData_TexelSize.y;
	
	vec4 data = textureLod(_HexCellData, uv, 0.0);
	return FilterCellData(data);
}














