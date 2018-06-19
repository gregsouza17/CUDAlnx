#include <stdio.h>

__global__ void glob(){

  // int i = threadIdx.x;
  // int j = blockIdx.x;


  printf("Hello World!\n");
  
  // printf("%d %d  \n", i,j);
	 
  
}

int main(void)
{

  // double b[10][10];
  // double *a;

  // cudaMalloc((void **)&a, sizeof(b));

  // cudaMemcpy(a,b,sizeof(b), cudaMemcpyHostToDevice);


  
  glob<<<1,1>>>();


  
  
  return 0;
}

