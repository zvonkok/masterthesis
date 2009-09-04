

const float Yn = 1.00000f;
const double Un_prime	= 0.19784977571475;
const double Vn_prime	= 0.46834507665248;



//define inline rounding function...
__device__ int my_round(float in_x)
{
	if (in_x < 0)
		return (int)(in_x - 0.5);
	else
		return (int)(in_x + 0.5);
}

// convert floating point rgba color to 32-bit integer
__device__ uint rgbaFloatToInt(float4 rgba)
{
    rgba.x = __saturatef(rgba.x);   // clamp to [0.0, 1.0]
    rgba.y = __saturatef(rgba.y);
    rgba.z = __saturatef(rgba.z);
    rgba.w = __saturatef(rgba.w);
    return (uint(rgba.w*255)<<24) | (uint(rgba.z*255)<<16) | (uint(rgba.y*255)<<8) | uint(rgba.x*255);
}


__global__ void luvtorgb(float4 *d_luv, unsigned int *d_rgb, unsigned int width)
{
	int ix = blockIdx.x * blockDim.x + threadIdx.x;
	int iy = blockIdx.y * blockDim.y + threadIdx.y;
	int i = ix + iy * width;
	
	float4 luv = d_luv[i];
	
	
	
	float RGB[3][3] = {
		{  3.2405f, -1.5371f, -0.4985f },
		{ -0.9693f,  1.8760f,  0.0416f },
		{  0.0556f, -0.2040f,  1.0573f }	
	};

	//declare variables...
	int	  r, g, b;
	float x, y, z, u_prime, v_prime;
	
	//perform conversion
	if(luv.x < 0.1)
		r = g = b = 0;
	else
	{
		//convert luv to xyz...
		if(luv.x < 8.0)
			y	= Yn * luv.x / 903.3;
		else
		{
			y = (luv.x + 16.0) / 116.0;
			y *= Yn * y * y;
		}
		
		u_prime	= luv.y / (13 * luv.x) + Un_prime;
		v_prime	= luv.z / (13 * luv.x) + Vn_prime;
		
		x = 9 * u_prime * y / (4 * v_prime);
		z = (12 - 3 * u_prime - 20 * v_prime) * y / (4 * v_prime);
		
		//convert xyz to rgb...
		//[r, g, b] = RGB*[x, y, z]*255.0
		r = my_round((RGB[0][0]*x + RGB[0][1]*y + RGB[0][2]*z)*255.0);
		g = my_round((RGB[1][0]*x + RGB[1][1]*y + RGB[1][2]*z)*255.0);
		b = my_round((RGB[2][0]*x + RGB[2][1]*y + RGB[2][2]*z)*255.0);
		
		//check bounds...
		if(r < 0)	r = 0; if(r > 255)	r = 255;
		if(g < 0)	g = 0; if(g > 255)	g = 255;
		if(b < 0)	b = 0; if(b > 255)	b = 255;
		
	}
	
	//assign rgb values to rgb vector rgb
	//rgb[0] = r;
	//rgb[1] = g;
	//rgb[2] = b;
	
	//float4 rgba = { rgb[0], rgb[1], rgb[2], 0.0f };
	
	//d_rgb[i] = rgbaFloatToInt(rgba);
	//done.
	
	((unsigned char*)&d_rgb[i])[0] = r;
	((unsigned char*)&d_rgb[i])[1] = g;
	((unsigned char*)&d_rgb[i])[2] = b;
	((unsigned char*)&d_rgb[i])[3] = 0;
	
	return;
	
}

extern "C" void luvToRgb(dim3 grid, dim3 threads, float4* d_luv, 
	unsigned int* d_rgb, unsigned int width)
{
	luvtorgb<<< grid, threads >>>(d_luv, d_rgb, width);
}


