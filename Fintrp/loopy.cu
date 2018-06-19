#include <stdio.h>
#include <cuda.h>


void free_data(double ***data, int xlen, int ylen);


extern __shared__ double cache[];

__global__ void kernel(int *Ss, int *Nn, int *mask, double *xyz,
		       double *cost){

  //block idx in 0, S
  //thread idx X 0,S and thread Idx Y 0,N
  //mask (N*k + j), cost( i1) xyz (N*S*k + S*j + i2)
  //cache =[threadIdx.x + threadIdx.y*blockDim.x]

  double temp=0;
  long int i1,i2,j, joffset=blockDim.y,i2offset=blockDim.x;
  int k, N=*Nn, S = *Ss, cacheIndex, cIndexMax;
  i1 = blockIdx.x; i2 = threadIdx.x;

  cacheIndex = threadIdx.x + threadIdx.y*blockDim.x;
  cIndexMax = blockDim.x*blockDim.y;


  while(i2<S){
   
    j = threadIdx.y;
    while(j<N){
      if (i1!=i2){ 
	// temp=0; 
	for(k=0; k<3; k++){
      
	  if( mask[k*N+j] ){ 
	
	//	temp+=1; 

	    //  printf("%f \t", xyz[i1+S*(j+N*k)]);
	    temp+=
	      (xyz[i1+S*(j+N*k)] - xyz[i2+S*(j+N*k)])* 
	      (xyz[i1+S*(j+N*k)] - xyz[i2+S*(j+N*k)]) ; 
	
	  } //if mask 

	} //k

      } //if i1!=i2
  
   
      __syncthreads();
      j+=joffset;
  } //while j<N;
    __syncthreads();
   i2+=i2offset;
  } //while i2<S

  __syncthreads();
   cache[cacheIndex]+= temp;


 

 
  //Somar todos os indices do cache aqui
  //ofset separado

  
  int i = cIndexMax/2;
  while (i != 0) {
    if (cacheIndex < i)
      cache[cacheIndex] += cache[cacheIndex + i];
    __syncthreads();
    i /= 2;
    
  }


  __syncthreads();

  cost[i1] = cache[0];
 
}

int main()
{

  //Max double array length: 523268
  // Max float array length: 1046537


  //Initializing
  long int N = 32, S = 32, sizexyz = N*S*3; 
  double xyz[3][N][S]; 
  double *linxyz;  
  double cost[S], soma;
  int mask[3][N]={0}, linmask[3*N];
  long int i1,i2;
  long int j=0,k=0;
 
  linxyz = (double *)malloc(sizexyz*sizeof(double));
  
  

  //mask
    for(k=0; k<3; k++){
      for(j=0; j<N; j++){
	mask[k][j] = 1;
	if(j%(k+1)==0)
	  mask[k][j] = 1;	
      }
    }
   
    for(k=0; k<3; k++){
      for(j=0; j<N; j++){
	linmask[j+N*k] = mask[k][j];
      }
    }


    //mask

    for(k=0; k<3; k++){
      for(j=0; j<N;j++){
	for(i1=0; i1<S; i1++){
	  xyz[k][j][i1] = 0.0001*i1;
	  linxyz[i1+S*j + S*N*k] = xyz[k][j][i1];
	  // printf("%f \n", linxyz[i1+S*j+S*N*k]);
	}
      }
    }


    //CPU
    soma = 0;

  for (i1 = 0  ; i1 < S ; ++i1) {    
    for (i2 = 0;   i2< S ; ++i2) {
        if(i1!=i2){
      	soma = 0;
      	for(j=0;   j<N;   j++){
	 
      	  for(k=0;   k<3;    k++){

	    if( mask[k][j] ){
	     
	      soma+=
		(linxyz[k*S*N+j*S +i1] -linxyz[k*S*N+j*S +i2])*
		(xyz[k][j][i1] -linxyz[k*S*N+j*S +i2]);
	      // }
	    }
	  } //for k
	
	} //for j
       	cost[i1]+=soma;
	} //for if
    } //for i2
  } //for i1

  //GPU

  int *devN, *devS;
  
  cudaMalloc((void **)&devN, sizeof(int));
  cudaMalloc((void **)&devS, sizeof(int));

  cudaMemcpy(devN, &N, sizeof(int), cudaMemcpyHostToDevice);
  cudaMemcpy(devS, &S, sizeof(int), cudaMemcpyHostToDevice);

  int *dmask;
  cudaMalloc((void **)&dmask, sizeof(linmask));

  cudaMemcpy(dmask, linmask, sizeof(linmask), cudaMemcpyHostToDevice);

  double *d_xyz, *d_cost, cost2[S]={0};
  cudaMalloc((void **)&d_xyz,sizexyz*sizeof(double) );
  cudaMalloc((void **)&d_cost, sizeof(cost));

  printf("%f \n" ,linxyz[17]);
  cudaMemcpy(d_xyz, linxyz, sizexyz*sizeof(double), cudaMemcpyHostToDevice);

  int threadX=16, threadY=16, cacheSize;

 
  dim3 threads(threadX,threadY);
  cacheSize = threadX*threadY;

  kernel<<<S, threads, cacheSize*sizeof(double)>>>(devS,devN, dmask, d_xyz,
						   d_cost);

  cudaMemcpy(cost2, d_cost, sizeof(cost2), cudaMemcpyDeviceToHost);
  

  for(i1=0; i1<S; i1+=10){
     printf("i1: %ld cost: %f dcost: %f\n", i1,cost[i1], cost2[i1]);
   }
  //printf("i1: %d cost: %f dcost: %f\n", 30,cost[30], cost2[30]);
  
  cudaFree(devN); cudaFree(devS); cudaFree(dmask);
  cudaFree(d_xyz); cudaFree(d_cost); free(linxyz);

  //free_data(xyz, 3, N);
  

  return 0;
}


void free_data(double ***data, int xlen, int ylen)
{
    size_t i, j;

    for (i=0; i < xlen; ++i) {
        if (data[i] != NULL) {
            for (j=0; j < ylen; ++j)
                free(data[i][j]);
            free(data[i]);
        }
    }
    free(data);
}
